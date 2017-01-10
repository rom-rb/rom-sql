require 'rom/schema/type'

module ROM
  module SQL
    class Type < ROM::Schema::Type
      # Return a new type marked as a FK
      #
      # @return [SQL::Type]
      #
      # @api public
      def foreign_key
        meta(foreign_key: true)
      end

      # Return a new type marked as qualified
      #
      # @return [SQL::Type]
      #
      # @api public
      def qualified
        if sql_expr
          meta(qualified: true).with_sql_expr
        else
          meta(qualified: true)
        end
      end

      # Return a new type with an alias
      #
      # @return [SQL::Type]
      #
      # @api public
      def aliased(aliaz)
        if sql_expr
          super.with_sql_expr
        else
          super
        end
      end

      # Return a new type marked as joined
      #
      # @return [SQL::Type]
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

      # @api private
      def with_sql_expr(expr = Sequel[to_sym])
        meta(sql_expr: expr)
      end

      # @api public
      def as(name)
        if sql_expr
          with_sql_expr(sql_expr.as(name))
        else
          super
        end
      end

      private

      # @api private
      def sql_expr
        meta[:sql_expr]
      end

      # @api private
      def method_missing(meth, *args, &block)
        if sql_expr
          with_sql_expr(sql_expr.__send__(meth, *args, &block))
        else
          super
        end
      end
    end
  end
end
