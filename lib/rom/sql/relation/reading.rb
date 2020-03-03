# frozen_string_literal: true

require 'rom/support/inflector'
require 'rom/sql/join_dsl'

module ROM
  module SQL
    class Relation < ROM::Relation
      # Query API for SQL::Relation
      #
      # @api public
      module Reading
        # Row-level lock modes
        ROW_LOCK_MODES = Hash.new(update: 'FOR UPDATE'.freeze).update(
          # https://www.postgresql.org/docs/current/static/sql-select.html#SQL-FOR-UPDATE-SHARE
          postgres: {
            update: 'FOR UPDATE'.freeze,
            no_key_update: 'FOR NO KEY UPDATE'.freeze,
            share: 'FOR SHARE'.freeze,
            key_share: 'FOR KEY SHARE'.freeze
          },
          # https://dev.mysql.com/doc/refman/5.7/en/innodb-locking-reads.html
          mysql: {
            update: 'FOR UPDATE'.freeze,
            share: 'LOCK IN SHARE MODE'.freeze
          }
        ).freeze

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
          limit(1).to_a.first
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
          reverse.limit(1).first
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
        def prefix(name = Inflector.singularize(schema.name.dataset))
          schema.prefix(name).(self)
        end

        # Qualifies all columns in a relation
        #
        # This method is intended to be used internally within a relation object
        #
        # @example
        #   users.qualified.dataset.sql
        #   # SELECT "users"."id", "users"."name" ...
        #
        # @return [Relation]
        #
        # @api public
        def qualified(table_alias = nil)
          schema.qualified(table_alias).(self)
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
          schema.qualified.map(&:to_sql_name)
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
        # @example Single value
        #   users.pluck(:id)
        #   # [1, 2]
        #
        # @example Multiple values
        #   users.pluck(:id, :name)
        #   # [[1, "Jane"] [2, "Joe"]]
        #
        # @return [Array]
        #
        # @api public
        def pluck(*names)
          select(*names).map(names.length == 1 ? names.first : names)
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
          schema.rename(options).(self)
        end

        # Select specific columns for select clause
        #
        # @overload select(*columns)
        #   Project relation using column names
        #
        #   @example using column names
        #     users.select(:id, :name).first
        #     # {:id => 1, :name => "Jane"}
        #
        #   @param [Array<Symbol>] columns A list of column names
        #
        # @overload select(*attributes)
        #   Project relation using schema attributes
        #
        #   @example using attributes
        #     users.select(:id, :name).first
        #     # {:id => 1, :name => "Jane"}
        #
        #   @example using schema
        #     users.select(*schema.project(:id)).first
        #     # {:id => 1}
        #
        #   @param [Array<SQL::Attribute>] columns A list of schema attributes
        #
        # @overload select(&block)
        #   Project relation using projection DSL
        #
        #   @example using attributes
        #     users.select { id.as(:user_id) }
        #     # {:user_id => 1}
        #
        #     users.select { [id, name] }
        #     # {:id => 1, :name => "Jane"}
        #
        #   @example using SQL functions
        #     users.select { string::concat(id, '-', name).as(:uid) }.first
        #     # {:uid => "1-Jane"}
        #
        # @overload select(*columns, &block)
        #   Project relation using column names and projection DSL
        #
        #   @example using attributes
        #     users.select(:id) { integer::count(id).as(:count) }.group(:id).first
        #     # {:id => 1, :count => 1}
        #
        #     users.select { [id, name] }
        #     # {:id => 1, :name => "Jane"}
        #
        #   @param [Array<SQL::Attribute>] columns A list of schema attributes
        #
        # @return [Relation]
        #
        # @api public
        def select(*args, &block)
          schema.project(*args, &block).(self)
        end
        alias_method :project, :select

        # Append specific columns to select clause
        #
        # @see Relation#select
        #
        # @return [Relation]
        #
        # @api public
        def select_append(*args, &block)
          schema.merge(schema.canonical.project(*args, &block)).(self)
        end

        # Returns a copy of the relation with a SQL DISTINCT clause.
        #
        # @overload distinct(*columns)
        #   Create a distinct statement from column names
        #
        #   @example
        #     users.distinct(:country)
        #
        #   @param [Array<Symbol>] columns A list with column names
        #
        # @overload distinct(&block)
        #   Create a distinct statement from a block
        #
        #   @example
        #     users.distinct { func(id) }
        #     # SELECT DISTINCT ON (count("id")) "id" ...
        #
        # @return [Relation]
        #
        # @api public
        def distinct(*args, &block)
          new(dataset.__send__(__method__, *args, &block))
        end

        # Returns a result of SQL SUM clause.
        #
        # @example
        #   users.sum(:age)
        #
        # @param [Array<Symbol>] args A list with column names
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
        # @param [Array<Symbol>] args A list with column names
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
        # @param [Array<Symbol>] args A list with column names
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
        # @param [Array<Symbol>] args A list with column names
        #
        # @return Number
        #
        # @api public
        def avg(*args)
          dataset.__send__(__method__, *args)
        end

        # Restrict a relation to match criteria
        #
        # @overload where(conditions)
        #   Restrict a relation using a hash with conditions
        #
        #   @example
        #     users.where(name: 'Jane', age: 30)
        #
        #   @param [Hash] conditions A hash with conditions
        #
        # @overload where(conditions, &block)
        #   Restrict a relation using a hash with conditions and restriction DSL
        #
        #   @example
        #     users.where(name: 'Jane') { age > 18 }
        #
        #   @param [Hash] conditions A hash with conditions
        #
        # @overload where(&block)
        #   Restrict a relation using restriction DSL
        #
        #   @example
        #     users.where { age > 18 }
        #     users.where { (id < 10) | (id > 20) }
        #
        # @return [Relation]
        #
        # @api public
        def where(*args, &block)
          if block
            where(*args).where(schema.canonical.restriction(&block))
          elsif args.size == 1 && args[0].is_a?(Hash)
            new(dataset.where(coerce_conditions(args[0])))
          elsif !args.empty?
            new(dataset.where(*args))
          else
            self
          end
        end

        # Restrict a relation to not match criteria
        #
        # @example
        #   users.exclude(name: 'Jane')
        #
        # @param [Hash] args A hash with conditions for exclusion
        #
        # @return [Relation]
        #
        # @api public
        def exclude(*args, &block)
          new(dataset.__send__(__method__, *args, &block))
        end

        # Restrict a relation to match grouping criteria
        #
        # @overload having(conditions)
        #   Return a new relation with having clause from conditions hash
        #
        #   @example
        #     users.
        #       qualified.
        #       left_join(tasks).
        #       select { [id, name, integer::count(:tasks__id).as(:task_count)] }.
        #       group(users[:id].qualified).
        #       having(task_count: 2)
        #       first
        #     # {:id => 1, :name => "Jane", :task_count => 2}
        #
        #   @param [Hash] conditions A hash with conditions
        #
        # @overload having(&block)
        #   Return a new relation with having clause created from restriction DSL
        #
        #   @example
        #     users.
        #       qualified.
        #       left_join(tasks).
        #       select { [id, name, integer::count(:tasks__id).as(:task_count)] }.
        #       group(users[:id].qualified).
        #       having { count(id.qualified) >= 1 }.
        #       first
        #     # {:id => 1, :name => "Jane", :task_count => 2}
        #
        # @return [Relation]
        #
        # @api public
        def having(*args, &block)
          if block
            new(dataset.having(*args, *schema.canonical.restriction(&block)))
          else
            new(dataset.__send__(__method__, *args))
          end
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
          new(dataset.invert)
        end

        # Set order for the relation
        #
        # @overload order(*columns)
        #   Return a new relation ordered by provided columns (ASC by default)
        #
        #   @example
        #     users.order(:name, :id)
        #
        #   @param [Array<Symbol>] columns A list with column names
        #
        # @overload order(*attributes)
        #   Return a new relation ordered by provided schema attributes
        #
        #   @example
        #     users.order(self[:name].qualified.desc, self[:id].qualified.desc)
        #
        #   @param [Array<SQL::Attribute>] attributes A list with schema attributes
        #
        # @overload order(&block)
        #   Return a new relation ordered using order DSL
        #
        #   @example using attribute
        #     users.order { id.desc }
        #     users.order { price.desc(nulls: :first) }
        #
        #   @example using a function
        #     users.order { nullif(name.qualified, `''`).desc(nulls: :first) }
        #
        # @return [Relation]
        #
        # @api public
        def order(*args, &block)
          if block
            new(dataset.order(*args, *schema.canonical.order(&block)))
          else
            new(dataset.__send__(__method__, *args, &block))
          end
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
          new(dataset.__send__(__method__, *args, &block))
        end

        # Limit a relation to a specific number of tuples
        #
        # @overload limit(num)
        #   Return a new relation with the limit set to the provided num
        #
        #   @example
        #     users.limit(1)
        #
        #   @param [Integer] num The limit value
        #
        # @overload limit(num, offset)
        #   Return a new relation with the limit set to the provided num
        #
        #   @example
        #     users.limit(10, 2)
        #
        #   @param [Integer] num The limit value
        #   @param [Integer] offset The offset value
        #
        # @return [Relation]
        #
        # @api public
        def limit(*args)
          new(dataset.__send__(__method__, *args))
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
        def offset(num)
          new(dataset.__send__(__method__, num))
        end

        # Join with another relation using INNER JOIN
        #
        # @overload join(dataset, join_conditions)
        #   Join with another relation using dataset name and join conditions
        #
        #   @example
        #     users.join(:tasks, id: :user_id)
        #
        #   @param [Symbol] dataset Join table name
        #   @param [Hash] join_conditions A hash with join conditions
        #
        # @overload join(dataset, join_conditions, options)
        #   Join with another relation using dataset name and join conditions
        #   with additional join options
        #
        #   @example
        #     users.join(:tasks, { id: :user_id }, { table_alias: :tasks_1 })
        #
        #   @param [Symbol] dataset Join table name
        #   @param [Hash] join_conditions A hash with join conditions
        #   @param [Hash] options Additional join options
        #
        # @overload join(relation)
        #   Join with another relation
        #
        #   Join conditions are automatically set based on schema association
        #
        #   @example
        #     users.join(tasks)
        #
        #   @param [Relation] relation A relation for join
        #
        # @overload join(relation, &block)
        #   Join with another relation using DSL
        #
        #   @example
        #     users.join(tasks) { |users:, tasks:|
        #       tasks[:user_id].is(users[:id]) & users[:name].is('John')
        #     }
        #
        #   @param [Relation] relation A relation for join
        #
        # @return [Relation]
        #
        # @api public
        def join(*args, &block)
          __join__(__method__, *args, &block)
        end
        alias_method :inner_join, :join

        # Join with another relation using LEFT OUTER JOIN
        #
        # @overload left_join(dataset, left_join_conditions)
        #   Left_Join with another relation using dataset name and left_join conditions
        #
        #   @example
        #     users.left_join(:tasks, id: :user_id)
        #
        #   @param [Symbol] dataset Left_Join table name
        #   @param [Hash] left_join_conditions A hash with left_join conditions
        #
        # @overload left_join(dataset, left_join_conditions, options)
        #   Left_Join with another relation using dataset name and left_join conditions
        #   with additional left_join options
        #
        #   @example
        #     users.left_join(:tasks, { id: :user_id }, { table_alias: :tasks_1 })
        #
        #   @param [Symbol] dataset Left_Join table name
        #   @param [Hash] left_join_conditions A hash with left_join conditions
        #   @param [Hash] options Additional left_join options
        #
        # @overload left_join(relation)
        #   Left_Join with another relation
        #
        #   Left_Join conditions are automatically set based on schema association
        #
        #   @example
        #     users.left_join(tasks)
        #
        #   @param [Relation] relation A relation for left_join
        #
        # @overload join(relation, &block)
        #   Join with another relation using DSL
        #
        #   @example
        #     users.left_join(tasks) { |users:, tasks:|
        #       tasks[:user_id].is(users[:id]) & users[:name].is('John')
        #     }
        #
        #   @param [Relation] relation A relation for left_join
        #
        # @return [Relation]
        #
        # @api public
        def left_join(*args, &block)
          __join__(__method__, *args, &block)
        end

        # Join with another relation using RIGHT JOIN
        #
        # @overload right_join(dataset, right_join_conditions)
        #   Right_Join with another relation using dataset name and right_join conditions
        #
        #   @example
        #     users.right_join(:tasks, id: :user_id)
        #
        #   @param [Symbol] dataset Right_Join table name
        #   @param [Hash] right_join_conditions A hash with right_join conditions
        #
        # @overload right_join(dataset, right_join_conditions, options)
        #   Right_Join with another relation using dataset name and right_join conditions
        #   with additional right_join options
        #
        #   @example
        #     users.right_join(:tasks, { id: :user_id }, { table_alias: :tasks_1 })
        #
        #   @param [Symbol] dataset Right_Join table name
        #   @param [Hash] right_join_conditions A hash with right_join conditions
        #   @param [Hash] options Additional right_join options
        #
        # @overload right_join(relation)
        #   Right_Join with another relation
        #
        #   Right_Join conditions are automatically set based on schema association
        #
        #   @example
        #     users.right_join(tasks)
        #
        #   @param [Relation] relation A relation for right_join
        #
        # @overload join(relation, &block)
        #   Join with another relation using DSL
        #
        #   @example
        #     users.right_join(tasks) { |users:, tasks:|
        #       tasks[:user_id].is(users[:id]) & users[:name].is('John')
        #     }
        #
        #   @param [Relation] relation A relation for right_join
        #
        # @return [Relation]
        #
        # @api public
        def right_join(*args, &block)
          __join__(__method__, *args, &block)
        end

        # Group by specific columns
        #
        # @overload group(*columns)
        #   Return a new relation grouped by provided columns
        #
        #   @example
        #     tasks.group(:user_id)
        #
        #   @param [Array<Symbol>] columns A list with column names
        #
        # @overload group(*attributes)
        #   Return a new relation grouped by provided schema attributes
        #
        #   @example
        #     tasks.group(tasks[:id], tasks[:title])
        #
        #   @param [Array<SQL::Attribute>] columns A list with relation attributes
        #
        # @overload group(*attributes, &block)
        #   Return a new relation grouped by provided attributes from a block
        #
        #   @example
        #     tasks.group(tasks[:id]) { title.qualified }
        #
        #   @param [Array<SQL::Attributes>] attributes A list with relation attributes
        #
        # @return [Relation]
        #
        # @api public
        def group(*args, &block)
          if block
            if args.size > 0
              group(*args).group_append(&block)
            else
              new(dataset.__send__(__method__, *schema.canonical.group(&block)))
            end
          else
            new(dataset.__send__(__method__, *schema.canonical.project(*args)))
          end
        end

        # Group by more columns
        #
        # @overload group_append(*columns)
        #   Return a new relation grouped by provided columns
        #
        #   @example
        #     tasks.group_append(:user_id)
        #
        #   @param [Array<Symbol>] columns A list with column names
        #
        # @overload group_append(*attributes)
        #   Return a new relation grouped by provided schema attributes
        #
        #   @example
        #     tasks.group_append(tasks[:id], tasks[:title])
        #
        # @overload group_append(*attributes, &block)
        #   Return a new relation grouped by provided schema attributes from a block
        #
        #   @example
        #     tasks.group_append(tasks[:id]) { id.qualified }
        #
        #   @param [Array<SQL::Attribute>] columns A list with column names
        #
        # @return [Relation]
        #
        # @api public
        def group_append(*args, &block)
          if block
            if args.size > 0
              group_append(*args).group_append(&block)
            else
              new(dataset.group_append(*schema.canonical.group(&block)))
            end
          else
            new(dataset.group_append(*args))
          end
        end

        # Group by specific columns and count by group
        #
        # @example
        #   tasks.group_and_count(:user_id)
        #   # => [{ user_id: 1, count: 2 }, { user_id: 2, count: 3 }]
        #
        # @param [Array<Symbol>] args A list of column names
        #
        # @return [Relation]
        #
        # @api public
        def group_and_count(*args, &block)
          new(dataset.__send__(__method__, *args, &block))
        end

        # Select and group by specific columns
        #
        # @example
        #   tasks.select_group(:user_id)
        #   # => [{ user_id: 1 }, { user_id: 2 }]
        #
        # @param [Array<Symbol>] args A list of column names
        #
        # @return [Relation]
        #
        # @api public
        def select_group(*args, &block)
          new_schema = schema.project(*args, &block)
          new_schema.(self).group(*new_schema)
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
        # @returRelation]
        #
        # @api public
        def union(relation, options = EMPTY_HASH, &block)
          # We use the original relation name here if both relations have the
          # same name. This makes it so if the user at some point references
          # the relation directly by name later on things won't break in
          # confusing ways.
          same_relation = name == relation.name
          alias_name =  same_relation ? name : "#{name.to_sym}__#{relation.name.to_sym}"
          opts = { alias: alias_name.to_sym, **options }

          new_schema = schema.qualified(opts[:alias])
          new_schema.(new(dataset.__send__(__method__, relation.dataset, opts, &block)))
        end

        # Checks whether a relation has at least one tuple
        #
        #  @example
        #    users.where(name: 'John').exist? # => true
        #
        #    users.exist?(name: 'Klaus') # => false
        #
        #    users.exist? { name.is('klaus') } # => false
        #
        #   @param [Array<Object>] args Optional restrictions to filter the relation
        #   @yield An optional block filters the relation using `where DSL`
        #
        # @return [TrueClass, FalseClass]
        #
        # @api public
        def exist?(*args, &block)
          !where(*args, &block).limit(1).count.zero?
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
        # @param [Hash] criteria The condition hash for WHERE clause
        #
        # @return [TrueClass, FalseClass]
        #
        # @api public
        def unique?(criteria)
          !exist?(criteria)
        end

        # Return a new relation from a raw SQL string
        #
        # @example
        #   users.read('SELECT name FROM users')
        #
        # @param [String] sql The SQL string
        #
        # @return [SQL::Relation]
        #
        # @api public
        def read(sql)
          new(dataset.db[sql], schema: schema.empty)
        end

        # Lock rows with in the specified mode. Check out ROW_LOCK_MODES for the
        # list of supported modes, keep in mind available lock modes heavily depend on
        # the database type+version you're running on.
        #
        # @overload lock(options)
        #   @option options [Symbol] :mode Lock mode
        #   @option options [Boolean,Integer] :wait Controls the (NO)WAIT part
        #   @option options [Boolean] :skip_locked Skip locked rows
        #   @option options [Array,Symbol,String] :of List of objects in the OF part
        #
        #   @return [SQL::Relation]
        #
        # @overload lock(options, &block)
        #   Runs the block inside a transaction. The relation will be materialized
        #   and passed inside the block so that the lock will be acquired right before
        #   the block gets executed.
        #
        #   @param [Hash] options The same options as for the version without a block
        #   @yieldparam relation [Array]
        #
        # @api public
        def lock(**options, &block)
          clause = lock_clause(**options)

          if block
            transaction do
              block.call(dataset.lock_style(clause).to_a)
            end
          else
            new(dataset.lock_style(clause))
          end
        end

        # Restrict with rows from another relation.
        # Accepts only SQL relations and uses the EXISTS
        # clause under the hood
        #
        # @example using associations
        #   users.exists(tasks)
        #
        # @example using provided condition
        #   users.exists(tasks, tasks[:user_id] => users[:id])
        #
        # @param [SQL::Relation] other The other relation
        # @param [Hash,Object] condition An optional join condition
        #
        # @return [SQL::Relation]
        #
        # @api public
        def exists(other, condition = nil)
          join_condition = condition || associations[other.name].join_keys
          where(other.where(join_condition).dataset.exists)
        end

        # Process the dataset in batches.
        # The method yields a relation restricted by a primary key value.
        # This means it discards any order internally and uses the PK sort.
        # Currently, works only with a single-column primary key.
        #
        # @example update in batches
        #   users.each_batch do |rel|
        #     rel.
        #       command(:update).
        #       call(name: users[:first_name].concat(users[:last_name])
        #   end
        #
        # @option [Integer] size The size of a batch (max number of records)
        # @yieldparam [SQL::Relation]
        #
        # @api public
        def each_batch(size: 1000)
          pks = schema.primary_key

          if pks.size > 1
            raise ArgumentError, 'Composite primary keys are not supported yet'
          end

          source = order(pks[0]).limit(size)
          rel = source

          loop do
            ids = rel.pluck(primary_key)

            break if ids.empty?

            yield(rel)

            break if ids.size < size

            rel = source.where(pks[0] > ids.last)
          end
        end

        # Returns hash with all tuples being
        # the key of each the provided attribute
        #
        # @example default use primary_key
        #   users.as_hash
        #   # {1 => {id: 1, name: 'Jane'}}
        #
        # @example using other attribute
        #   users.as_hash(:name)
        #   # {'Jane' => {id: 1, name: 'Jane'}}
        #
        # @return [Hash]
        #
        # @api public
        def as_hash(attribute = primary_key)
          dataset.as_hash(attribute)
        end

        # Turn a relation into a subquery. Can be used
        # for selecting a column with a subquery or
        # restricting the result set with a IN (SELECT ...) condtion.
        #
        # @example adding number of user tasks
        #   tasks = relations[:tasks]
        #   users = relations[:users]
        #   user_tasks = tasks.where(tasks[:user_id].is(users[:id]))
        #   tasks_count = user_tasks.select { integer::count(id) }
        #   users.select_append(tasks_count.as(:tasks_count))
        #
        # @return [SQL::Attribute]
        def query
          attr = schema.to_a[0]
          subquery = schema.project(attr).(self).dataset
          SQL::Attribute[attr.type].meta(sql_expr: subquery)
        end

        # Discard restrictions in `WHERE` and `HAVING` clauses
        #
        # @example calling .by_pk has no effect
        #   users.by_pk(1).unfiltered
        #
        # @return [SQL::Relation]
        #
        # @api public
        def unfiltered
          new(dataset.__send__(__method__))
        end

        # Wrap other relations using association names
        #
        # @example
        #   tasks.wrap(:owner)
        #
        # @param [Array<Symbol>] names A list with association identifiers
        #
        # @return [Wrap]
        #
        # @api public
        def wrap(*names)
          others = names.map { |name| associations[name].wrapped }
          wrap_around(*others)
        end

        private

        # Build a locking clause
        #
        # @api private
        def lock_clause(mode: :update, skip_locked: false, of: nil, wait: nil)
          stmt = ROW_LOCK_MODES[dataset.db.database_type].fetch(mode).dup
          stmt << ' OF ' << Array(of).join(', ') if of

          if skip_locked
            raise ArgumentError, 'SKIP LOCKED cannot be used with (NO)WAIT clause' if !wait.nil?

            stmt << ' SKIP LOCKED'
          else
            case wait
            when Integer
              stmt << ' WAIT ' << wait.to_s
            when false
              stmt << ' NOWAIT'
            else
              stmt
            end
          end
        end

        # Apply input types to condition values
        #
        # @api private
        def coerce_conditions(conditions)
          conditions.each_with_object({}) { |(k, v), h|
            if k.is_a?(Symbol) && schema.canonical.key?(k)
              type = schema.canonical[k]
              h[k] = v.is_a?(Array) ? v.map { |e| type[e] } : type[v]
            elsif k.is_a?(ROM::SQL::Attribute)
              h[k.canonical] = v
            else
              h[k] = v
            end
          }
        end

        # Common join method used by other join methods
        #
        # @api private
        def __join__(type, other, join_cond = EMPTY_HASH, opts = EMPTY_HASH, &block)
          if other.is_a?(Symbol) || other.is_a?(ROM::Relation::Name)
            if join_cond.equal?(EMPTY_HASH) && !block
              assoc = associations[other]
              assoc.join(type, self)
            elsif block
              __join__(type, other, JoinDSL.new(schema).(&block), opts)
            else
              new(dataset.__send__(type, other.to_sym, join_cond, opts, &block))
            end
          elsif other.is_a?(Sequel::SQL::AliasedExpression)
            new(dataset.__send__(type, other, join_cond, opts, &block))
          elsif other.respond_to?(:name) && other.name.is_a?(Relation::Name)
            if block
              join_cond = JoinDSL.new(schema).(&block)

              if other.name.aliaz
                join_opts = { table_alias: other.name.aliaz }
              else
                join_opts = EMPTY_HASH
              end

              new(dataset.__send__(type, other.name.dataset.to_sym, join_cond, join_opts))
            else
              associations[other.name.key].join(type, self, other)
            end
          else
            raise ArgumentError, "+other+ must be either a symbol or a relation, #{other.class} given"
          end
        end
      end
    end
  end
end
