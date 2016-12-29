require 'rom/sql/dsl'
require 'rom/sql/function'

module ROM
  module SQL
    class ProjectionDSL < DSL
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
