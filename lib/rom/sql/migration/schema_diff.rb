module ROM
  module SQL
    module Migration
      class SchemaDiff
        def self.compare(current, target)
          current_attrs, target_attrs = current.to_a, target.to_a
          new_attributes = target_attrs - current_attrs

          if current_attrs.empty?
            TableAdded.new(target)
          else
            raise NotImplementedError, 'Only create_table available'
          end
        end

        class TableAdded
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
                  column attribute.name, attribute.type.primitive, null: false
                end
              end
            end
          end
        end
      end
    end
  end
end
