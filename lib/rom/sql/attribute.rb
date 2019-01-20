require 'sequel/core'
require 'dry/core/cache'

require 'rom/attribute'

require 'rom/sql/type_extensions'
require 'rom/sql/projection_dsl'

module ROM
  module SQL
    # Extended schema attributes tailored for SQL databases
    #
    # @api public
    class Attribute < ROM::Attribute
      OPERATORS = %i[>= <= > <].freeze
      NONSTANDARD_EQUALITY_VALUES = [true, false, nil].freeze
      META_KEYS = %i(index foreign_key target sql_expr qualified).freeze

      # Error raised when an attribute cannot be qualified
      QualifyError = Class.new(StandardError)

      extend Dry::Core::Cache

      # @api private
      def self.[](*args)
        fetch_or_store(args) { new(*args) }
      end

      # Return a new attribute with an alias
      #
      # @example
      #   users[:id].aliased(:user_id)
      #
      # @return [SQL::Attribute]
      #
      # @api public
      def aliased(alias_name)
        super.with(name: name || alias_name).meta(
          sql_expr: sql_expr.as(alias_name)
        )
      end
      alias_method :as, :aliased

      # Return a new attribute in its canonical form
      #
      # @api public
      def canonical
        if aliased?
          with(alias: nil).meta(sql_expr: nil)
        else
          self
        end
      end

      # Return a new attribute marked as qualified
      #
      # @example
      #   users[:id].aliased(:user_id)
      #
      # @return [SQL::Attribute]
      #
      # @api public
      def qualified(table_alias = nil)
        return self if qualified? && table_alias.nil?
        return meta(qualified: false) unless qualifiable?

        case sql_expr
        when Sequel::SQL::AliasedExpression, Sequel::SQL::Identifier, Sequel::SQL::QualifiedIdentifier
          attr = meta(qualified: table_alias || true)
          attr.meta(sql_expr: attr.to_sql_name)
        else
          raise QualifyError, "can't qualify #{name.inspect} (#{sql_expr.inspect})"
        end
      end

      # Return a new attribute marked as joined
      #
      # Whenever you join two schemas, the right schema's attribute
      # will be marked as joined using this method
      #
      # @return [SQL::Attribute] Original attribute marked as joined
      #
      # @api public
      def joined
        meta(joined: true)
      end

      # Return if an attribute was used in a join
      #
      # @example
      #   schema = users.schema.join(tasks.schema)
      #
      #   schema[:id, :tasks].joined?
      #   # => true
      #
      # @return [Boolean]
      #
      # @api public
      def joined?
        meta[:joined].equal?(true)
      end

      # Return if an attribute type is qualified
      #
      # @example
      #   id = users[:id].qualify
      #
      #   id.qualified?
      #   # => true
      #
      # @return [Boolean]
      #
      # @api public
      def qualified?
        meta[:qualified].equal?(true) || meta[:qualified].is_a?(Symbol)
      end

      # Return if an attribute is qualifiable
      #
      # @return [Boolean]
      #
      # @api public
      def qualifiable?
        !source.nil?
      end

      # Return a new attribute marked as a FK
      #
      # @return [SQL::Attribute]
      #
      # @api public
      def foreign_key
        meta(foreign_key: true)
      end

      # Return symbol representation of an attribute
      #
      # This uses convention from sequel where double underscore in the name
      # is used for qualifying, and triple underscore means aliasing
      #
      # @example
      #   users[:id].qualified.to_sym
      #   # => :users__id
      #
      #   users[:id].as(:user_id).to_sym
      #   # => :id___user_id
      #
      #   users[:id].qualified.as(:user_id).to_sym
      #   # => :users__id___user_id
      #
      # @return [Symbol]
      #
      # @api public
      def to_sym
        @_to_sym ||=
          if qualified? && aliased?
            :"#{table_name}__#{name}___#{meta[:alias]}"
          elsif qualified?
            :"#{table_name}__#{name}"
          elsif aliased?
            :"#{name}___#{meta[:alias]}"
          else
            name
          end
      end

      # Return a boolean expression with an equality operator
      #
      # @example
      #   users.where { id.is(1) }
      #
      #   users.where(users[:id].is(1))
      #
      # @param [Object] other Any SQL-compatible object type
      #
      # @api public
      def is(other)
        self =~ other
      end

      # Return a new attribute with an equality expression
      #
      # @example
      #   users.where { email =~ 1 }
      #
      # @return [Attribute]
      #
      # @api public
      def =~(other)
        meta(sql_expr: sql_expr =~ binary_operation_arg(other))
      end

      # Return a boolean expression with a negated equality operator
      #
      # @example
      #   users.where { id.not(1) }
      #
      #   users.where(users[:id].not(1))
      #
      # @param [Object] other Any SQL-compatible object type
      #
      # @api public
      def not(other)
        !is(other)
      end

      # Negate the attribute's sql expression
      #
      # @example
      #   users.where(!users[:id].is(1))
      #
      # @return [Attribute]
      #
      # @api public
      def !
        ~self
      end

      # Return a boolean expression with an inclusion test
      #
      # If the single argument passed to the method is a Range object
      # then the resulting expression will restrict the attribute value
      # with range's bounds. Upper bound condition will be inclusive/non-inclusive
      # depending on the range type.
      #
      # If more than one argument is passed to the method or the first
      # argument is not Range then the result will be a simple IN check.
      #
      # @example
      #   users.where { id.in(1..100) | created_at(((Time.now - 86400)..Time.now)) }
      #   users.where { id.in(1, 2, 3) }
      #   users.where(users[:id].in(1, 2, 3))
      #
      # @param [Array<Object>] args A range or a list of values for an inclusion check
      #
      # @api public
      def in(*args)
        if args.first.is_a?(Range)
          range = args.first
          lower_cond = __cmp__(:>=, range.begin)
          upper_cond = __cmp__(range.exclude_end? ? :< : :<=, range.end)

          Sequel::SQL::BooleanExpression.new(:AND, lower_cond, upper_cond)
        else
          __cmp__(:IN, args)
        end
      end

      # Create a function DSL from the attribute
      #
      # @example
      #   users[:id].func { int::count(id).as(:count) }
      #
      # @return [SQL::Function]
      #
      # @api public
      def func(&block)
        ProjectionDSL.new(name => self).call(&block).first
      end

      # Create a CONCAT function from the attribute
      #
      # @example with default separator (' ')
      #   users[:id].concat(users[:name])
      #
      # @example with custom separator
      #   users[:id].concat(users[:name], '-')
      #
      # @param [SQL::Attribute] other
      #
      # @return [SQL::Function]
      #
      # @api public
      def concat(other, sep = ' ')
        Function.new(type).concat(self, sep, other)
      end

      # Sequel calls this method to coerce an attribute into SQL string
      #
      # @param [Sequel::Dataset] ds
      #
      # @api private
      def sql_literal(ds)
        ds.literal(sql_expr)
      end

      # Sequel column representation
      #
      # @return [Sequel::SQL::AliasedExpression,Sequel::SQL::Identifier]
      #
      # @api private
      def to_sql_name
        @_to_sql_name ||=
          if qualified? && aliased?
            Sequel.qualify(table_name, name).as(self.alias)
          elsif qualified?
            Sequel.qualify(table_name, name)
          elsif aliased?
            Sequel.as(name, self.alias)
          else
            Sequel[name]
          end
      end

      # @api public
      def indexed?
        meta[:index].equal?(true)
      end

      # Returns a new attribute marked as indexed
      #
      # @api public
      def indexed
        meta(index: true)
      end

      # @api private
      def meta_options_ast
        meta = super
        meta[:index] = true if indexed?
        meta
      end

      # Removes metadata from the type
      #
      # @api private
      def unwrap
        cleaned_meta = meta.reject { |k, _| META_KEYS.include?(k) }
        type = optional? ? right : self.type

        self.class.new(type.with(meta: cleaned_meta), options)
      end

      # Wrap a value with the type, it allows using attribute and type specific methods
      # on literals and things like this
      #
      # @param [Object] value any SQL-serializable value
      # @return [SQL::Attribute]
      #
      # @api public
      def value(value)
        meta(sql_expr: Sequel[value])
      end

      # Build a case expression based on attribute. See SQL::Function#case
      # when you don't have a specific expression after the CASE keyword.
      # Pass the :else keyword to provide the catch-all case, it's mandatory
      # because of the Sequel's API used underneath.
      #
      # @example
      #   users.select_append { id.case(1 => `'first'`, else: `'other'`).as(:first_or_not) }
      #
      # @param [Hash] mapping mapping between SQL expressions
      # @return [SQL::Attribute]
      #
      # @api public
      def case(mapping)
        mapping = mapping.dup
        otherwise = mapping.delete(:else) do
          raise ArgumentError, 'provide the default case using the :else keyword'
        end

        type = mapping.values[0].type

        Attribute[type].meta(sql_expr: ::Sequel.case(mapping, otherwise, self))
      end

      private

      # Return Sequel Expression object for an attribute
      #
      # @api private
      def sql_expr
        @sql_expr ||= (meta[:sql_expr] || to_sql_name)
      end

      # Delegate to sql expression if it responds to a given method
      #
      # @api private
      def method_missing(meth, *args, &block)
        if OPERATORS.include?(meth)
          __cmp__(meth, args[0])
        elsif extensions.key?(meth)
          extensions[meth].(type, sql_expr, *args, &block)
        elsif sql_expr.respond_to?(meth)
          meta(sql_expr: sql_expr.__send__(meth, *args, &block))
        else
          super
        end
      end

      # A simple wrapper for the boolean expression constructor where
      # the left part is the attribute value
      #
      # @api private
      def __cmp__(op, other)
        Sequel::SQL::BooleanExpression.new(op, self, binary_operation_arg(other))
      end

      # Preprocess input value for binary operations
      #
      # @api private
      def binary_operation_arg(value)
        case value
        when Sequel::SQL::Expression
          value
        else
          type[value]
        end
      end

      # Return source table name or its alias
      #
      # @api private
      def table_name
        if qualified? && meta[:qualified].is_a?(Symbol)
          meta[:qualified]
        else
          source.dataset
        end
      end

      # @api private
      def extensions
        TypeExtensions[type]
      end

      memoize :joined, :to_sql_name, :table_name, :canonical
    end
  end
end
