module ROM
  module SQL
    class Expression
      attr_reader :expr, :type

      def initialize(type, expr = ::Sequel.expr(type.to_sym))
        @type = type
        @expr = expr
      end

      def sql_literal(ds)
        expr.sql_literal(ds)
      end

      private

      def method_missing(meth, *args, &block)
        if type.respond_to?(meth)
          self.class.new(type.__send__(meth, *args, &block))
        else
          self.class.new(type, expr.__send__(meth, *args, &block))
        end
      end
    end
  end
end
