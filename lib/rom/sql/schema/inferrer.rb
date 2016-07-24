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

        # @api private
        def call(dataset, gateway)
          columns = gateway.connection.schema(dataset)
          fks = fks_for(gateway, dataset)

          columns.each do |(name, definition)|
            dsl.attribute name, build_type(definition.merge(foreign_key: fks[name]))
          end

          pks = columns
            .map { |(name, definition)| name if definition.fetch(:primary_key) }
            .compact

          dsl.primary_key(*pks) if pks.any?

          dsl.attributes
        end

        private

        # @api private
        def build_type(primary_key: , type: , allow_null: , foreign_key: , **rest)
          if primary_key
            self.class.pk_type
          else
            type = self.class.type_mapping.fetch(type)
            type = type.optional if allow_null
            type = type.meta(foreign_key: true, relation: foreign_key) if foreign_key
            type
          end
        end

        # @api private
        def fks_for(gateway, dataset)
          gateway.connection.foreign_key_list(dataset).each_with_object({}) do |definition, fks|
            column, fk = build_fk(definition)

            fks[column] = fk if fk
          end
        end

        # @api private
        def build_fk(columns: , table: , **rest)
          if columns.size == 1
            [columns[0], table]
          else
            # We don't have support for multicolumn foreign keys
            columns[0]
          end
        end
      end
    end
  end
end
