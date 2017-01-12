module ROM
  module SQL
    class Function < ROM::Schema::Type
      def sql_literal(ds)
        if name
          func.as(name).sql_literal(ds)
        else
          func.sql_literal(ds)
        end
      end

      def name
        meta[:alias] || super
      end

      private

      def func
        meta[:func]
      end

      def method_missing(meth, *args)
        if func && func.respond_to?(meth)
          meta(func: func.__send__(meth, *args))
        else
          meta(func: Sequel::SQL::Function.new(meth.to_s.upcase, *args))
        end
      end
    end
  end
end
