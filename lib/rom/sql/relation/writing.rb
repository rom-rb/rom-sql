# frozen_string_literal: true

module ROM
  module SQL
    class Relation < ROM::Relation
      module Writing
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
      end
    end
  end
end
