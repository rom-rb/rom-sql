# frozen_string_literal: true

module ROM
  module SQL
    # Type DSL used by Types.define method
    #
    # @api public
    class TypeDSL
      attr_reader :definition, :input_constructor, :output_constructor

      # @api private
      def initialize(value_type)
        if value_type.class < ::Dry::Types::Type
          @definition = value_type
        else
          @definition = ::ROM::SQL::Types.Nominal(value_type)
        end
      end

      # @api private
      def call(&block)
        instance_exec(&block)

        definition.constructor(input_constructor)
          .meta(read: definition.constructor(output_constructor))
      end

      # @api private
      def input(&block)
        @input_constructor = block
      end

      # @api private
      def output(&block)
        @output_constructor = block
      end
    end
  end
end
