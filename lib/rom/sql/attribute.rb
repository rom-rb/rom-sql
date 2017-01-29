require 'sequel/core'

require 'rom/schema/attribute'
require 'rom/sql/projection_dsl'

module ROM
  module SQL
    # Extended schema attributes tailored for SQL databases
    #
    # @api public
    class Attribute < ROM::Schema::Attribute
      # Error raised when an attribute cannot be qualified
      QualifyError = Class.new(StandardError)

      # Return a new attribute with an alias
      #
      # @example
      #   users[:id].aliased(:user_id)
      #
      # @return [SQL::Attribute]
      #
      # @api public
      def aliased(name)
        super.meta(sql_expr: sql_expr.as(name))
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

      # @api public
      def is(other)
        Sequel::SQL::BooleanExpression.new(:'=', self, other)
      end

      # @api public
      def func(&block)
        ProjectionDSL.new(name => self).call(&block).first
      end

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
        if sql_expr.respond_to?(meth)
          meta(sql_expr: sql_expr.__send__(meth, *args, &block))
        else
          super
        end
      end
    end
  end
end
