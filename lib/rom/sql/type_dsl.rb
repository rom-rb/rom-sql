module ROM
  module SQL
    class TypeDSL
      attr_reader :definition, :input_constructor, :output_constructor

      def initialize(value_type)
        if value_type.class < ::Dry::Types::Type
          @definition = value_type
        else
          @definition = ::ROM::SQL::Types.Definition(value_type)
        end
      end

      def call(&block)
        instance_exec(&block)

        definition.constructor(input_constructor)
          .meta(read: definition.constructor(output_constructor))
      end

      def input(&block)
        @input_constructor = block
      end

      def output(&block)
        @output_constructor = block
      end
    end
  end
end
