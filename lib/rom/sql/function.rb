module ROM
  module SQL
    class Function < ROM::Schema::Type
      def as(name)
        meta(name: name)
      end

      def sql_literal(ds)
        func.as(name).sql_literal(ds)
      end

      if RUBY_VERSION < '2.3'
        def to_ary
          [self]
        end
      end

      private

      def func
        Sequel::SQL::Function.new(meta[:op], *meta[:args])
      end

      def method_missing(op, *args)
        meta(op: op, args: args)
      end
    end
  end
end
