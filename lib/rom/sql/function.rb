require 'rom/schema/attribute'

module ROM
  module SQL
    # @api private
    class Function < ROM::Schema::Attribute
      def sql_literal(ds)
        if name
          ds.literal(func.as(name))
        else
          ds.literal(func)
        end
      end

      def name
        meta[:alias] || super
      end

      def qualified
        meta(
          func: ::Sequel::SQL::Function.new(func.name, *func.args.map { |arg| arg.respond_to?(:qualified) ? arg.qualified : arg })
        )
      end

      def is(other)
        ::Sequel::SQL::BooleanExpression.new(:'=', func, other)
      end

      # Convert an expression result to another data type
      #
      # @example
      #   users.select { bool::cast(json_data.get_text('activated'), :boolean).as(:activated) }
      #
      # @param [ROM::SQL::Attribute] expr Expression to be cast
      # @param [String] db_type Target database type
      #
      # @return [ROM::SQL::Attribute]
      #
      # @api private
      def cast(expr, db_type)
        Attribute[type].meta(sql_expr: ::Sequel.cast(expr, db_type))
      end

      private

      def func
        meta[:func]
      end

      def method_missing(meth, *args)
        if func
          if func.respond_to?(meth)
            meta(func: func.__send__(meth, *args))
          else
            super
          end
        else
          meta(func: Sequel::SQL::Function.new(meth.to_s.upcase, *args))
        end
      end
    end
  end
end
