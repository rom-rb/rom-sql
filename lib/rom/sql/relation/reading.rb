module ROM
  module SQL
    class Relation < ROM::Relation
      # Query API for SQL::Relation
      #
      # @api public
      module Reading
        # Fetch a tuple identified by the pk
        #
        # @example
        #   users.fetch(1)
        #   # {:id => 1, name: "Jane"}
        #
        # @return [Relation]
        #
        # @raise [ROM::TupleCountMismatchError] When 0 or more than 1 tuples were found
        #
        # @api public
        def fetch(pk)
          by_pk(pk).one!
        end

        # Return relation count
        #
        # @example
        #   users.count
        #   # => 12
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
        #   # {:id => 1, :name => "Jane"}
        #
        # @return [Hash]
        #
        # @api public
        def first
          dataset.first
        end

        # Get last tuple from the relation
        #
        # @example
        #   users.last
        #   # {:id => 2, :name => "Joe"}
        #
        # @return [Hash]
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
        #   users.prefix(:user).to_a
        #   # {:user_id => 1, :user_name => "Jane"}
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
        #   users.qualified
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
        # @example
        #   users.qualified_columns
        #   # [:users__id, :users__name]
        #
        # @return [Array<Symbol>]
        #
        # @api public
        def qualified_columns
          header.qualified.to_a
        end

        # Map tuples from the relation
        #
        # @example
        #   users.map { |user| user[:id] }
        #   # [1, 2, 3]
        #
        #   users.map(:id).to_a
        #   # [1, 2, 3]
        #
        # @param [Symbol] key An optional name of the key for extracting values
        #                     from tuples
        #
        # @api public
        def map(key = nil, &block)
          if key
            dataset.map(key, &block)
          else
            dataset.map(&block)
          end
        end

        # Pluck values from a specific column
        #
        # @example
        #   users.pluck(:id)
        #   # [1, 2, 3]
        #
        # @return [Array]
        #
        # @api public
        def pluck(name)
          map(name)
        end

        # Project a relation
        #
        # This method is intended to be used internally within a relation object
        #
        # @example
        #   users.project(:id, :name) }
        #
        # @param [Symbol] *names A list of symbol column names
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
        #   users.rename(name: :user_name).first
        #   # {:id => 1, :user_name => "Jane" }
        #
        # @param [Hash<Symbol=>Symbol>] options A name => new_name map
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
        #   users.select(:id, :name).first
        #   # {:id => 1, :name => "Jane" }
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
        #   # {:id => 1, :name => "Jane", :email => "jane@doe.org"}
        #
        # @param [Array<Symbol>] *args A list with column names
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
        # @param [Array<Symbol>] *args A list with column names
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
        # @param [Array<Symbol>] *args A list with column names
        #
        # @return [Integer]
        #
        # @api public
        def sum(*args)
          dataset.__send__(__method__, *args)
        end

        # Returns a result of SQL MIN clause.
        #
        # @example
        #   users.min(:age)
        #
        # @param [Array<Symbol>] *args A list with column names
        #
        # @return Number
        #
        # @api public
        def min(*args)
          dataset.__send__(__method__, *args)
        end

        # Returns a result of SQL MAX clause.
        #
        # @example
        #   users.max(:age)
        #
        # @param [Array<Symbol>] *args A list with column names
        #
        # @return Number
        #
        # @api public
        def max(*args)
          dataset.__send__(__method__, *args)
        end

        # Returns a result of SQL AVG clause.
        #
        # @example
        #   users.avg(:age)
        #
        # @param [Array<Symbol>] *args A list with column names
        #
        # @return Number
        #
        # @api public
        def avg(*args)
          dataset.__send__(__method__, *args)
        end

        # Restrict a relation to match criteria
        #
        # If block is passed it'll be executed in the context of a condition
        # builder object.
        #
        # @example
        #   users.where(name: 'Jane')
        #
        #   users.where { age >= 18 }
        #
        # @param [Hash] *args An optional hash with conditions for WHERE clause
        #
        # @return [Relation]
        #
        # @see http://sequel.jeremyevans.net/rdoc/files/doc/dataset_filtering_rdoc.html
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
        # @param [Hash] *args A hash with conditions for exclusion
        #
        # @return [Relation]
        #
        # @api public
        def exclude(*args, &block)
          __new__(dataset.__send__(__method__, *args, &block))
        end

        # Restrict a relation to match grouping criteria
        #
        # @example
        #   users.with_task_count.having( task_count: 2 )
        #
        #   users.with_task_count.having { task_count > 3 }
        #
        # @param [Hash] *args An optional hash with conditions for HAVING clause
        #
        # @return [Relation]
        #
        # @see http://sequel.jeremyevans.net/rdoc/files/doc/dataset_filtering_rdoc.html
        #
        # @api public
        def having(*args, &block)
          __new__(dataset.__send__(__method__, *args, &block))
        end

        # Inverts the current WHERE and HAVING clauses. If there is neither a
        # WHERE or HAVING clause, adds a WHERE clause that is always false.
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
        def invert
          __new__(dataset.invert)
        end

        # Set order for the relation
        #
        # @example
        #   users.order(:name)
        #
        # @param [Array<Symbol>] *args A list with column names
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
        #   users.limit(10, 2)
        #
        # @param [Integer] limit The limit value
        # @param [Integer] offset An optional offset
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
        # @param [Integer] num The offset value
        #
        # @return [Relation]
        #
        # @api public
        def offset(*args, &block)
          __new__(dataset.__send__(__method__, *args, &block))
        end

        # Join with another relation using INNER JOIN
        #
        # @example
        #   users.inner_join(:tasks, id: :user_id)
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

        # Join other relation using LEFT OUTER JOIN
        #
        # @example
        #   users.left_join(:tasks, id: :user_id)
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
        # @param [Array<Symbol>] *args A list of column names
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
        # @param [Array<Symbol>] *args A list of column names
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
        # @param [Array<Symbol>] *args A list of column names
        #
        # @return [Relation]
        #
        # @api public
        def select_group(*args, &block)
          __new__(dataset.__send__(__method__, *args, &block))
        end

        # Adds a UNION clause for relation dataset using second relation dataset
        #
        # @example
        #   users.where(id: 1).union(users.where(id: 2))
        #   # => [{ id: 1, name: 'Piotr' }, { id: 2, name: 'Jane' }]
        #
        # @param [Relation] relation Another relation
        #
        # @param [Hash] options Options for union
        # @option options [Symbol] :alias Use the given value as the #from_self alias
        # @option options [TrueClass, FalseClass] :all Set to true to use UNION ALL instead of UNION, so duplicate rows can occur
        # @option options [TrueClass, FalseClass] :from_self Set to false to not wrap the returned dataset in a #from_self, use with care.
        #
        # @return [Relation]
        #
        # @api public
        def union(relation, options = EMPTY_HASH, &block)
          __new__(dataset.__send__(__method__, relation.dataset, options, &block))
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
        # @param [Hash] criteria The condition hash for  WHERE clause
        #
        # @return [TrueClass, FalseClass]
        #
        # @api public
        def unique?(criteria)
          where(criteria).count.zero?
        end
      end
    end
  end
end
