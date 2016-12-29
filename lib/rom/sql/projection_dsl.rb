require 'rom/sql/dsl'
require 'rom/sql/function'

module ROM
  module SQL
    class ProjectionDSL < DSL
      # @api private
      def call(&block)
        ::Kernel.Array(instance_exec(&block))
      end

      # @api private
      def respond_to_missing?(name, include_private = false)
        super || type(name)
      end

      private

      # @api private
      def type(identifier)
        type_name = ::Dry::Core::Inflector.classify(identifier)
        types.const_get(type_name) if types.const_defined?(type_name)
      end

      # @api private
      def types
        ::ROM::SQL::Types
      end

      # @api private
      def method_missing(meth, *args, &block)
        if schema.key?(meth)
          schema[meth]
        else
          type = type(meth)

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
