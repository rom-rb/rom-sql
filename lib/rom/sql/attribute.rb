require 'rom/schema/attribute'

module ROM
  module SQL
    # Extended schema attributes tailored for SQL databases
    #
    # @api public
    class Attribute < ROM::Schema::Attribute
      QualifyError = Class.new(StandardError)

      # Return a new type marked as a FK
      #
      # @return [SQL::Attribute]
      #
      # @api public
      def foreign_key
        meta(foreign_key: true)
      end

      # @api public
      def aliased(name)
        super.meta(sql_expr: sql_expr.as(name))
      end
      alias_method :as, :aliased

      # Return a new type marked as qualified
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

      # Return a new type marked as joined
      #
      # @return [SQL::Attribute]
      #
      # @api public
      def joined
        meta(joined: true)
      end

      # Return if an attribute was used in a join
      #
      # @return [Boolean]
      #
      # @api public
      def joined?
        meta[:joined].equal?(true)
      end

      # Return if an attribute type is qualified
      #
      # @return [Boolean]
      #
      # @api public
      def qualified?
        meta[:qualified].equal?(true)
      end

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

      # @api private
      def sql_literal(ds)
        if sql_expr
          sql_expr.sql_literal(ds)
        else
          Sequel[to_sym].sql_literal(ds)
        end
      end

      private

      # @api private
      def sql_expr
        @sql_expr ||= (meta[:sql_expr] || Sequel[to_sym])
      end

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
