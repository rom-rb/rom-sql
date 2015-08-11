module ROM
  module SQL
    class Relation < ROM::Relation
      module Writing
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
