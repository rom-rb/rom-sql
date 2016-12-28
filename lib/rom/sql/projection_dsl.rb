module ROM
  module SQL
    class Function < ROM::Schema::Type
      def as(aliaz)
        aliased(aliaz)
      end

      def sql_literal_append(ds, sql)
        if aliased?
          ds.literal_append(sql, func.as(meta[:alias]))
        else
          ds.literal_append(sql, func)
        end
      end

      if RUBY_VERSION < '2.3'
        def to_ary
          [self]
        end
      end

      private

      def func
        Sequel::SQL::Function.new(name, *meta[:args])
      end

      def method_missing(name, *args)
        meta(name: name, args: args)
      end
    end

    class ProjectionDSL < BasicObject
      attr_reader :schema

      def initialize(schema)
        @schema = schema
        @attributes = []
      end

      def call(&block)
        ::Kernel.Array(instance_exec(&block))
      end

      private

      def type(identifier)
        types.const_get(::Dry::Core::Inflector.classify(identifier))
      end

      def types
        ::ROM::SQL::Types
      end

      # @api private
      def method_missing(name, *args, &block)
        if schema.key?(name)
          schema[name]
        else
          type = type(name)

          if type
            ::ROM::SQL::Function.new(type)
          else
            super
          end
        end
      end
    end
  end
end
