module ROM
  module SQL
    class Schema < ROM::Schema
      # @api private
      class Inferrer
        extend ClassMacros

        defines :type_mapping, :pk_type, :db_type, :db_registry

        type_mapping(
          integer: Types::Strict::Int,
          string: Types::Strict::String,
          date: Types::Strict::Date,
          datetime: Types::Strict::Time,
          boolean: Types::Strict::Bool,
          decimal: Types::Strict::Decimal,
          float: Types::Strict::Float,
          blob: Types::Strict::String
        ).freeze

        pk_type Types::Serial

        db_registry Hash.new(self)

        def self.inherited(klass)
          super

          Inferrer.db_registry[klass.db_type] = klass unless klass.name.nil?
        end

        def self.[](type)
          Class.new(self) { db_type(type) }
        end

        def self.get(type)
          if !db_registry.key?(type) && ROM::SQL.available_extension?(type)
            ROM::SQL.load_extensions(type)
          end

          db_registry[type]
        end

        def call(dataset, gateway)
          columns = gateway.connection.schema(dataset)
          fks = fks_for(gateway, dataset)

          columns.each_with_object({}) do |(name, definition), attrs|
            type = build_type(definition.merge(foreign_key: fks[name]))
            attrs[name] = type.meta(name: name)
          end
        end

        private

        def build_type(primary_key: , db_type: , type: , allow_null: , foreign_key: , **rest)
          if primary_key
            self.class.pk_type.meta(primary_key: true)
          else
            type ||= db_type.to_sym
            mapped_type = self.class.type_mapping.fetch(type) {
              raise UnknownDBTypeError, "Cannot find corresponding type for #{type}"
            }
            mapped_type = mapped_type.optional if allow_null
            mapped_type = mapped_type.meta(foreign_key: true, relation: foreign_key) if foreign_key
            mapped_type
          end
        end

        def fks_for(gateway, dataset)
          gateway.connection.foreign_key_list(dataset).each_with_object({}) do |definition, fks|
            column, fk = build_fk(definition)

            fks[column] = fk if fk
          end
        end

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
