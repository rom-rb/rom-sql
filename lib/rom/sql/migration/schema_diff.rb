module ROM
  module SQL
    module Migration
      class SchemaDiff
        def self.compare(current, target)
          current_attrs, target_attrs = current.to_a, target.to_a
          new_attributes = target_attrs - current_attrs

          if current_attrs.empty?
            TableCreated.new(target)
          elsif !new_attributes.empty?
            TableAltered.new(target, new_attributes: new_attributes)
          end
        end

        class TableCreated
          attr_reader :schema

          def initialize(schema)
            @schema = schema
          end

          def apply(gateway)
            attributes = schema.to_a

            gateway.create_table(schema.name.dataset) do
              attributes.each do |attribute|
                if attribute.primary_key?
                  primary_key attribute.name
                else
                  unwrapped = attribute.optional? ? attribute.right : attribute
                  column attribute.name, unwrapped.primitive, null: attribute.optional?
                end
              end
            end
          end
        end

        class TableAltered
          attr_reader :schema, :new_attributes

          def initialize(schema, new_attributes: [])
            @schema = schema
            @new_attributes = new_attributes
          end

          def apply(gateway)
            attributes = new_attributes

            gateway.connection.alter_table(schema.name.dataset) do
              attributes.each do |attribute|
                unwrapped = attribute.optional? ? attribute.right : attribute
                add_column attribute.name, unwrapped.primitive, null: attribute.optional?
              end
            end
          end
        end
      end
    end
  end
end
