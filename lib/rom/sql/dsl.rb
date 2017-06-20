module ROM
  module SQL
    # @api private
    class DSL < BasicObject
      # @api private
      attr_reader :schema

      # @api private
      def initialize(schema)
        @schema = schema
      end

      # @api private
      def call(&block)
        result = instance_exec(&block)

        if result.is_a?(::Array)
          result
        else
          [result]
        end
      end

      # @api private
      def respond_to_missing?(name, include_private = false)
        super || schema.key?(name)
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
    end
  end
end
