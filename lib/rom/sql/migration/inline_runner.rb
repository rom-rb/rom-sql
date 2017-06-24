module ROM
  module SQL
    module Migration
      class Migrator
        # @api private
        class InlineRunner
          attr_reader :gateway

          def initialize(gateway)
            @gateway = gateway
          end

          def call(changes)
            changes.each do |diff|
              apply(diff)
            end
          end

          def apply(diff)
            case diff
            when SchemaDiff::TableCreated
              create_table(diff)
            when SchemaDiff::TableAltered
              alter_table(diff)
            else
              raise NotImplementedError
            end
          end

          def create_table(diff)
            gateway.create_table(diff.table_name) do
              diff.attributes.each do |attribute|
                if attribute.primary_key?
                  primary_key attribute.name
                else
                  column attribute.name, attribute.type, null: attribute.null?
                  index attribute.name if attribute.indexed?
                end
              end
            end
          end

          def alter_table(diff)
            gateway.connection.alter_table(diff.table_name) do
              diff.attribute_changes.each do |attribute|
                case attribute
                when SchemaDiff::AttributeAdded
                  add_column attribute.name, attribute.type, null: attribute.null?
                  add_index attribute.name if attribute.indexed?
                when SchemaDiff::AttributeRemoved
                  drop_column attribute.name
                when SchemaDiff::AttributeChanged
                  add_index attribute.name if attribute.index_added?
                  drop_index attribute.name if attribute.index_removed?
                end
              end
            end
          end
        end
      end
    end
  end
end
