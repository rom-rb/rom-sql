module ROM
  module SQL
    # @api private
    class TypeSerializer
      MAPPING = {
        Types::Int => 'integer',
        Types::String => 'string',
        Types::Time => 'timestamp',
        Types::Date => 'date',
        Types::Bool => 'boolean',
        Types::Decimal => 'numeric',
        Types::Float => 'float',
      }

      def call(type)
        MAPPING.fetch(type) { raise "Cannot serialize #{ type }" }
      end
    end
  end
end
