require 'rom/constants'

module ROM
  module SQL
    # @api private
    class DSL < BasicObject
      # @!attribute [r] schema
      #   @return [SQL::Schema]
      attr_reader :schema

      # @!attribute [r] relations
      #   @return [Hash, RelationRegistry]
      attr_reader :relations

      # @api private
      def initialize(schema)
        @schema = schema
        @relations = schema.respond_to?(:relations) ? schema.relations : EMPTY_HASH
      end

      # @api private
      def call(&block)
        result = instance_exec(relations, &block)

        if result.is_a?(::Array)
          result
        else
          [result]
        end
      end

      # Return a string literal that will be used directly in an ORDER clause
      #
      # @param [String] value
      #
      # @return [Sequel::LiteralString]
      #
      # @api public
      def `(value)
        ::Sequel.lit(value)
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
