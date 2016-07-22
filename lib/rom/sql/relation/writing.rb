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
        #                { target: :email, update: { name: :excluded__name } }
        #
        # @api public
        def upsert(*args, &block)
          if args.size > 1 && args[-1].is_a?(Hash)
            *values, opts = args
          else
            values = args
            opts = EMPTY_HASH
          end

          dataset.insert_conflict(opts).insert(*values, &block)
        end

        # Insert tuple into relation
        #
        # @example
        #   users.insert(name: 'Jane')
        #
        # @param [Hash] tuple
        #
        # @return [Relation]
        #
        # @api public
        def insert(*args, &block)
          dataset.insert(*args, &block)
        end

        # Multi insert tuples into relation
        #
        # @example
        #   users.multi_insert([{name: 'Jane'}, {name: 'Jack'}])
        #
        # @param [Array] tuples
        #
        # @return [Relation]
        #
        # @api public
        def multi_insert(*args, &block)
          dataset.multi_insert(*args, &block)
        end

        # Update tuples in the relation
        #
        # @example
        #   users.update(name: 'Jane')
        #   users.where(name: 'Jane').update(name: 'Jane Doe')
        #
        # @return [Relation]
        #
        # @api public
        def update(*args, &block)
          dataset.update(*args, &block)
        end

        # Delete tuples from the relation
        #
        # @example
        #   users.delete # deletes all
        #   users.where(name: 'Jane').delete # delete tuples
        #                                      from restricted relation
        #
        # @return [Relation]
        #
        # @api public
        def delete(*args, &block)
          dataset.delete(*args, &block)
        end
      end
    end
  end
end
