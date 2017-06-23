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
              diff.schema.to_a.each do |attribute|
                if attribute.primary_key?
                  primary_key attribute.name
                else
                  unwrapped = attribute.optional? ? attribute.right : attribute
                  column attribute.name, unwrapped.primitive, null: attribute.optional?

                  index attribute.name if attribute.indexed?
                end
              end
            end
          end

          def alter_table(diff)
            gateway.connection.alter_table(diff.table_name) do
              diff.added.each do |name, attribute|
                unwrapped = attribute.optional? ? attribute.right : attribute
                add_column name, unwrapped.primitive, null: attribute.optional?
                add_index name if attribute.indexed?
              end

              diff.removed.each do |name, _|
                drop_column name
              end

              diff.changed.each do |name, (from, to)|
                if !from.indexed? && to.indexed?
                  add_index name
                end
              end
            end
          end
        end
      end
    end
  end
end
