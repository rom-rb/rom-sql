module ROM
  module SQL
    class Schema < ROM::Schema
      class Inferrer
        extend ClassMacros

        defines :type_mapping, :pk_type

        type_mapping(
          integer: Types::Strict::Int,
          string: Types::Strict::String,
          date: Types::Strict::Date,
          datetime: Types::Strict::Time,
          boolean: Types::Strict::Bool,
          decimal: Types::Strict::Decimal,
          blob: Types::Strict::String
        ).freeze

        pk_type Types::Serial

        attr_reader :dsl

        def initialize(dsl)
          @dsl = dsl
        end

        def call(dataset, gateway)
          columns = gateway.connection.schema(dataset)

          columns.each do |(name, definition)|
            dsl.attribute name, build_type(definition)
          end

          pks = columns.select { |(name, definition)| definition.fetch(:primary_key) }.map(&:first)

          dsl.primary_key *pks if pks.any?
          dsl.attributes
        end

        def build_type(definition)
          if definition.fetch(:primary_key)
            self.class.pk_type
          else
            type = self.class.type_mapping.fetch(definition.fetch(:type))
            type = type.optional if definition.fetch(:allow_null)
            type
          end
        end
      end
    end
  end
end
