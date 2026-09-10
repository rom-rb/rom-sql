# frozen_string_literal: true

require 'rom/sql/upsert_dsl'

module ROM
  module SQL
    class Relation < ROM::Relation
      module Writing
        # Handle conflicts with unique constraints on insert
        #
        # Returns a relation carrying an ON CONFLICT clause, so any insert
        # through it becomes an upsert: `insert`, `multi_insert`, `import`,
        # `command(:create)` and changesets. Conflicts are ignored unless
        # `do_update` is chained.
        #
        # @example ignore conflicting rows
        #   users.on_conflict(:email).insert(name: 'Jane', email: 'jane@doe.org')
        #
        # @example infer a partial unique index
        #   users.on_conflict(:email) { active.is(true) }.insert(...)
        #
        # @example use a named constraint
        #   users.on_conflict(constraint: :users_email_key).insert(...)
        #
        # @param [Array<Symbol, SQL::Attribute>] target Columns of the unique index
        # @param [Symbol] constraint Name of the constraint, takes precedence over target
        #
        # @yield Index predicate built with the restriction DSL
        #
        # @return [Relation]
        #
        # @api public
        def on_conflict(*target, constraint: nil, &block)
          opts = conflict_options.except(:target, :constraint, :conflict_where)
          opts[:constraint] = constraint if constraint
          opts[:target] = target.map { |t| t.is_a?(Attribute) ? t.name : t } unless target.empty?
          opts[:conflict_where] = schema.canonical.restriction(&block) if block

          new(insert_conflict(opts))
        end

        # Update the existing row on conflict
        #
        # Without arguments every column except the primary key and the
        # conflict target is set from the excluded row, i.e. the one proposed
        # for insertion. Listed columns restrict that, pairs set arbitrary
        # values, and the block gives access to the upsert DSL.
        #
        # @example set columns from the excluded row
        #   users.on_conflict(:email).do_update(:name, :updated_at).insert(...)
        #
        # @example set values and expressions
        #   users.on_conflict(:email).do_update(removed_at: nil).insert(...)
        #
        # @example use the DSL
        #   users.on_conflict(:email).do_update {
        #     set(last_seen_at: greatest(last_seen_at, excluded[:last_seen_at]))
        #       .where(updated_at < excluded[:updated_at])
        #   }.multi_insert(tuples)
        #
        # @param [Array<Symbol>] columns Columns to set from the excluded row
        # @param [Hash] pairs Column-value pairs
        #
        # @yield Block evaluated with the upsert DSL, returns `set(...)` or a hash
        #
        # @return [Relation]
        #
        # @see UpsertDSL
        #
        # @api public
        def do_update(*columns, **pairs, &)
          assignments, condition = conflict_update(columns, pairs, &)

          opts = conflict_options.except(:update_where).merge(update: assignments)
          opts[:update_where] = condition if condition

          new(insert_conflict(opts))
        end

        # Ignore the conflicting row
        #
        # This is the default of `on_conflict`, the method exists to revert
        # a previous `do_update`
        #
        # @return [Relation]
        #
        # @api public
        def do_nothing
          new(insert_conflict(conflict_options.except(:update, :update_where)))
        end

        # Row proposed for insertion in ON CONFLICT DO UPDATE
        #
        # @example
        #   users.on_conflict(:email).do_update(name: users.excluded[:name])
        #
        # @return [SQL::Schema] Schema with attributes qualified with `excluded`
        #
        # @api public
        def excluded
          schema.qualified(:excluded)
        end

        # Add upsert option (only PostgreSQL >= 9.5)
        # Uses internal Sequel implementation
        # Default - ON CONFLICT DO NOTHING
        # more options: http://sequel.jeremyevans.net/rdoc-adapters/classes/Sequel/Postgres/DatasetMethods.html#method-i-insert_conflict
        #
        # @example
        #   users.upsert({ name: 'Jane', email: 'jane@foo.com' },
        #                { target: :email, update: { name: :excluded__name } })
        #
        # @return [Integer] Number of affected rows
        #
        # @api public
        def upsert(*args, &)
          if args.size > 1 && args[-1].is_a?(Hash)
            *values, opts = args
          else
            values = args
            opts = EMPTY_HASH
          end

          dataset.insert_conflict(opts).insert(*values, &)
        end

        # Insert tuple into relation
        #
        # @example
        #   users.insert(name: 'Jane')
        #
        # @param [Hash] args
        #
        # @return [Hash] Inserted tuple
        #
        # @api public
        def insert(...)
          dataset.insert(...)
        end

        # Multi insert tuples into relation
        #
        # @example
        #   users.multi_insert([{name: 'Jane'}, {name: 'Jack'}])
        #
        # @param [Array<Hash>] args
        #
        # @return [Array<String>] A list of executed SQL statements
        #
        # @api public
        def multi_insert(...)
          dataset.multi_insert(...)
        end

        # Update tuples in the relation
        #
        # @example
        #   users.update(name: 'Jane')
        #   users.where(name: 'Jane').update(name: 'Jane Doe')
        #
        # @return [Integer] Number of updated rows
        #
        # @api public
        def update(...)
          dataset.update(...)
        end

        # Delete tuples from the relation
        #
        # @example
        #   users.delete # deletes all
        #   users.where(name: 'Jane').delete # delete tuples
        #                                      from restricted relation
        #
        # @return [Integer] Number of deleted tuples
        #
        # @api public
        def delete(...)
          dataset.delete(...)
        end

        # Insert tuples from other relation
        #
        # NOTE: The method implicitly uses a transaction
        #
        # @example
        #   users.import(new_users)
        #
        # @overload import(other_sql_relation, options)
        #   If both relations uses the same gateway
        #   the INSERT ... SELECT statement will
        #   be used for importing the data
        #
        #   @param [SQL::Relation] other_sql_relation
        #
        #   @option [Integer] :slice
        #     Split loading into batches of provided size,
        #     every batch will be processed in a separate
        #     transaction block
        #
        # @overload import(other, options)
        #   Import data from another relation. The source
        #   relation will be materialized before loading
        #
        #   @param [Relation] other
        #
        #   @option [Integer] :slice
        #
        # @return [Integer] Number of imported tuples
        #
        # @api public
        def import(other, options = EMPTY_HASH)
          columns = other.schema.map { |a| a.alias || a.name }

          if other.gateway.eql?(gateway)
            dataset.import(columns, other.dataset, options)
          else
            keys = columns.map(&:to_sym)
            dataset.import(
              columns,
              other.to_a.map { |record|
                record.to_h.values_at(*keys)
              },
              options
            )
          end
        end

        private

        # @api private
        def insert_conflict(opts)
          unless dataset.respond_to?(:insert_conflict)
            raise UnsupportedFeatureError,
                  "ON CONFLICT is not supported by #{dataset.db.database_type}"
          end

          dataset.insert_conflict(opts)
        end

        # Options of the ON CONFLICT clause set on the dataset
        #
        # @api private
        def conflict_options
          opts = dataset.opts[:insert_conflict] || dataset.opts[:insert_on_conflict]
          opts.is_a?(Hash) ? opts : EMPTY_HASH
        end

        # Assignments and condition of the DO UPDATE clause
        #
        # @return [Array(Hash, Object)]
        #
        # @api private
        def conflict_update(columns, pairs, &block)
          assignments = columns.to_h { |column| [column, excluded[column]] }.merge(pairs)
          condition = nil

          if block
            dsl_assignments, condition = UpsertDSL.new(schema).call(&block)
            assignments = assignments.merge(dsl_assignments)
          end

          assignments = default_conflict_assignments if assignments.empty?

          [assignments.to_h { |k, v| [k.is_a?(Attribute) ? k.name : k, v] }, condition]
        end

        # Every column except the primary key and the conflict target
        #
        # @api private
        def default_conflict_assignments
          keys = schema.primary_key.map(&:name) + Array(conflict_options[:target])
          (schema.map(&:name) - keys).to_h { |name| [name, excluded[name]] }
        end
      end
    end
  end
end
