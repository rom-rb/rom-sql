require 'sequel/core'

require 'rom/schema/attribute'
require 'rom/sql/projection_dsl'

module ROM
  module SQL
    # Extended schema attributes tailored for SQL databases
    #
    # @api public
    class Attribute < ROM::Schema::Attribute
      OPERATORS = %i[>= <= > <].freeze

      # Error raised when an attribute cannot be qualified
      QualifyError = Class.new(StandardError)

      # Type-specific methods
      #
      # @api public
      module TypeExtensions
        class << self
          # Gets extensions for a type
          #
          # @param [Dry::Types::Type] type
          #
          # @return [Hash]
          #
          # @api public
          def [](type)
            @types[unwrap_type(type)] || EMPTY_HASH
          end

          # Unwraps an optional type
          #
          # TODO: add Type#optional? method to dry-types and clean this up
          #
          # @api private
          def unwrap_type(type)
            if type.respond_to?(:left) && type.left == Types::Strict::Nil
              type.right
            else
              type
            end
          end

          # Registers a set of operations supported for a specific type
          #
          # @example
          #   ROM::SQL::Attribute::TypeExtensions.register(ROM::SQL::Types::PG::JSONB) do
          #     def contains(type, keys)
          #       Sequel::Postgres::JSONBOp.new(type.meta[:name]).contains(keys)
          #     end
          #   end
          #
          # @param [Dry::Types::Type] type Type
          #
          # @api public
          def register(type, &block)
            raise ArgumentError, "Type #{ type } already registered" if @types.key?(type)
            mod = Module.new(&block)
            ctx = Object.new.extend(mod)
            functions = mod.instance_methods.each_with_object({}) { |m, ms| ms[m] = ctx.method(m) }
            @types[type] = functions
          end
        end

        @types = {}
      end

      option :extensions, type: Dry::Types['hash'], default: -> { TypeExtensions[type] }

      # Return a new attribute with an alias
      #
      # @example
      #   users[:id].aliased(:user_id)
      #
      # @return [SQL::Attribute]
      #
      # @api public
      def aliased(name)
        super.meta(name: meta.fetch(:name, name), sql_expr: sql_expr.as(name))
      end
      alias_method :as, :aliased

      # Return a new attribute in its canonical form
      #
      # @api public
      def canonical
        if aliased?
          meta(alias: nil, sql_expr: nil)
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
      def qualified
        return self if qualified?

        case sql_expr
        when Sequel::SQL::AliasedExpression, Sequel::SQL::Identifier
          type = meta(qualified: true)
          type.meta(qualified: true, sql_expr: Sequel[type.to_sym])
        else
          raise QualifyError, "can't qualify #{name.inspect} (#{sql_expr.inspect})"
        end
      end

      # Return a new attribute marked as joined
      #
      # Whenever you join two schemas, the right schema's attribute
      # will be marked as joined using this method
      #
      # @return [SQL::Attribute]
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
        meta[:qualified].equal?(true)
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
            :"#{source.dataset}__#{name}___#{meta[:alias]}"
          elsif qualified?
            :"#{source.dataset}__#{name}"
          elsif aliased?
            :"#{name}___#{meta[:alias]}"
          else
            name
          end
      end

      # Return a boolean expression with `=` operator
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
        __cmp__(:'=', other)
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
      # @param [Array<Object>] *args A range or a list of values for an inclusion check
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
      # @param [Sequel::Dataset]
      #
      # @api private
      def sql_literal(ds)
        if sql_expr
          sql_expr.sql_literal(ds)
        else
          Sequel[to_sym].sql_literal(ds)
        end
      end

      private

      # Return Sequel Expression object for an attribute
      #
      # @api private
      def sql_expr
        @sql_expr ||= (meta[:sql_expr] || Sequel[to_sym])
      end

      # Delegate to sql expression if it responds to a given method
      #
      # @api private
      def method_missing(meth, *args, &block)
        if OPERATORS.include?(meth)
          __cmp__(meth, args[0])
        elsif sql_expr.respond_to?(meth)
          meta(sql_expr: sql_expr.__send__(meth, *args, &block))
        elsif extensions.key?(meth)
          extensions[meth].(type, *args, &block)
        else
          super
        end
      end

      # A simple wrapper for the boolean expression constructor where
      # the left part is the attribute value
      #
      # @api private
      def __cmp__(op, other)
        value =
          case other
          when Sequel::SQL::Expression
            value
          else
            type[other]
          end

        Sequel::SQL::BooleanExpression.new(op, self, value)
      end
    end
  end
end
