module ROM
  module SQL
    class Relation < ROM::Relation
      module Reading
        # Return relation count
        #
        # @example
        #   users.count # => 12
        #
        # @return [Relation]
        #
        # @api public
        def count
          dataset.count
        end

        # Get first tuple from the relation
        #
        # @example
        #   users.first
        #
        # @return [Relation]
        #
        # @api public
        def first
          dataset.first
        end

        # Get last tuple from the relation
        #
        # @example
        #   users.last
        #
        # @return [Relation]
        #
        # @api public
        def last
          dataset.last
        end

        # Prefix all columns in a relation
        #
        # This method is intended to be used internally within a relation object
        #
        # @example
        #   rom.relation(:users) { |r| r.prefix(:user) }
        #
        # @param [Symbol] name The prefix
        #
        # @return [Relation]
        #
        # @api public
        def prefix(name = Inflector.singularize(table))
          rename(header.prefix(name).to_h)
        end

        # Qualifies all columns in a relation
        #
        # This method is intended to be used internally within a relation object
        #
        # @example
        #   rom.relation(:users) { |r| r.qualified }
        #
        # @return [Relation]
        #
        # @api public
        def qualified
          select(*qualified_columns)
        end

        # Return a list of qualified column names
        #
        # This method is intended to be used internally within a relation object
        #
        # @return [Relation]
        #
        # @api public
        def qualified_columns
          header.qualified.to_a
        end

        # Return if a restricted relation has 0 tuples
        #
        # @example
        #   users.unique?(email: 'jane@doe.org') # true
        #
        #   users.insert(email: 'jane@doe.org')
        #
        #   users.unique?(email: 'jane@doe.org') # false
        #
        # @param [Hash] criteria hash for the where clause
        #
        # @return [Relation]
        #
        # @api public
        def unique?(criteria)
          where(criteria).count.zero?
        end

        # Map tuples from the relation
        #
        # @example
        #   users.map { |user| ... }
        #
        # @api public
        def map(&block)
          dataset.map(&block)
        end

        # Project a relation
        #
        # This method is intended to be used internally within a relation object
        #
        # @example
        #   rom.relation(:users) { |r| r.project(:id, :name) }
        #
        # @param [Symbol] names A list of symbol column names
        #
        # @return [Relation]
        #
        # @api public
        def project(*names)
          select(*header.project(*names))
        end

        # Rename columns in a relation
        #
        # This method is intended to be used internally within a relation object
        #
        # @example
        #   rom.relation(:users) { |r| r.rename(name: :user_name) }
        #
        # @param [Hash] options A name => new_name map
        #
        # @return [Relation]
        #
        # @api public
        def rename(options)
          select(*header.rename(options))
        end

        # Select specific columns for select clause
        #
        # @example
        #   users.select(:id, :name)
        #
        # @return [Relation]
        #
        # @api public
        def select(*args, &block)
          __new__(dataset.__send__(__method__, *args, &block))
        end

        # Append specific columns to select clause
        #
        # @example
        #   users.select(:id, :name).select_append(:email)
        #
        # @return [Relation]
        #
        # @api public
        def select_append(*args, &block)
          __new__(dataset.__send__(__method__, *args, &block))
        end

        # Returns a copy of the relation with a SQL DISTINCT clause.
        #
        # @example
        #   users.distinct(:country)
        #
        # @return [Relation]
        #
        # @api public
        def distinct(*args, &block)
          __new__(dataset.__send__(__method__, *args, &block))
        end

        # Returns a result of SQL SUM clause.
        #
        # @example
        #   users.sum(:age)
        #
        # @return Number
        #
        # @api public
        def sum(*args)
          dataset.__send__(__method__, *args)
        end

        # Restrict a relation to match criteria
        #
        # @example
        #   users.where(name: 'Jane')
        #
        # @return [Relation]
        #
        # @api public
        def where(*args, &block)
          __new__(dataset.__send__(__method__, *args, &block))
        end

        # Restrict a relation to not match criteria
        #
        # @example
        #   users.exclude(name: 'Jane')
        #
        # @return [Relation]
        #
        # @api public
        def exclude(*args, &block)
          __new__(dataset.__send__(__method__, *args, &block))
        end

        # Inverts a request
        #
        # @example
        #   users.exclude(name: 'Jane').invert
        #
        #   # this is the same as:
        #   users.where(name: 'Jane')
        #
        # @return [Relation]
        #
        # @api public
        def invert(*args, &block)
          __new__(dataset.__send__(__method__, *args, &block))
        end

        # Set order for the relation
        #
        # @example
        #   users.order(:name)
        #
        # @return [Relation]
        #
        # @api public
        def order(*args, &block)
          __new__(dataset.__send__(__method__, *args, &block))
        end

        # Reverse the order of the relation
        #
        # @example
        #   users.order(:name).reverse
        #
        # @return [Relation]
        #
        # @api public
        def reverse(*args, &block)
          __new__(dataset.__send__(__method__, *args, &block))
        end

        # Limit a relation to a specific number of tuples
        #
        # @example
        #   users.limit(1)
        #
        # @return [Relation]
        #
        # @api public
        def limit(*args, &block)
          __new__(dataset.__send__(__method__, *args, &block))
        end

        # Set offset for the relation
        #
        # @example
        #   users.limit(10).offset(2)
        #
        # @return [Relation]
        #
        # @api public
        def offset(*args, &block)
          __new__(dataset.__send__(__method__, *args, &block))
        end

        # Join other relation using inner join
        #
        # @param [Symbol] relation name
        # @param [Hash] join keys
        #
        # @return [Relation]
        #
        # @api public
        def inner_join(*args, &block)
          __new__(dataset.__send__(__method__, *args, &block))
        end

        # Join other relation using left outer join
        #
        # @param [Symbol] relation name
        # @param [Hash] join keys
        #
        # @return [Relation]
        #
        # @api public
        def left_join(*args, &block)
          __new__(dataset.__send__(__method__, *args, &block))
        end

        # Group by specific columns
        #
        # @example
        #   tasks.group(:user_id)
        #
        # @return [Relation]
        #
        # @api public
        def group(*args, &block)
          __new__(dataset.__send__(__method__, *args, &block))
        end

        # Group by specific columns and count by group
        #
        # @example
        #   tasks.group_and_count(:user_id)
        #   # => [{ user_id: 1, count: 2 }, { user_id: 2, count: 3 }]
        #
        # @return [Relation]
        #
        # @api public
        def group_and_count(*args, &block)
          __new__(dataset.__send__(__method__, *args, &block))
        end

        # Select and group by specific columns
        #
        # @example
        #   tasks.select_group(:user_id)
        #   # => [{ user_id: 1 }, { user_id: 2 }]
        #
        # @return [Relation]
        #
        # @api public
        def select_group(*args, &block)
          __new__(dataset.__send__(__method__, *args, &block))
        end

        # Adds a UNION clause for relation dataset using second relation dataset
        #
        # @param [Relation] relation object
        #
        # @example
        #   users.where(id: 1).union(users.where(id: 2))
        #   # => [{ id: 1, name: 'Piotr' }, { id: 2, name: 'Jane' }]
        #
        # @return [Relation]
        #
        # @api public
        def union(relation, *args, &block)
          __new__(dataset.__send__(__method__, relation.dataset, *args, &block))
        end
      end
    end
  end
end
