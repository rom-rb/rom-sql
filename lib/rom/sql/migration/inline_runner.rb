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
                end
              end

              diff.indexes.each do |idx|
                index idx.attribute
              end
            end
          end

          def alter_table(diff)
            gateway.connection.alter_table(diff.table_name) do
              diff.attribute_changes.each do |attribute|
                case attribute
                when SchemaDiff::AttributeAdded
                  add_column attribute.name, attribute.type, null: attribute.null?
                when SchemaDiff::AttributeRemoved
                  drop_column attribute.name
                when SchemaDiff::AttributeChanged
                  if attribute.type_changed?
                    from, to = attribute.to_a.map(&attribute.method(:unwrap))
                    raise UnsupportedConversion.new(
                            "Don't know how to convert #{ from.inspect } to #{ to.inspect }"
                          )
                  end

                  if attribute.nullability_changed?
                    if attribute.null?
                      set_column_allow_null attribute.name
                    else
                      set_column_not_null attribute.name
                    end
                  end
                end
              end

              diff.index_changes.each do |index|
                case index
                when SchemaDiff::IndexAdded
                  add_index index.attribute, name: index.name
                when SchemaDiff::IndexRemoved
                  drop_index index.attribute, name: index.name
                end
              end
            end
          end
        end
      end
    end
  end
end
