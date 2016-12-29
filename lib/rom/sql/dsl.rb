module ROM
  module SQL
    class DSL < BasicObject
      attr_reader :schema

      def initialize(schema)
        @schema = schema
      end
    end
  end
end
