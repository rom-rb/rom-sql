module ROM
  module SQL
    module Migration
      class SchemaDiff
        def self.compare(current, target)
          current_attrs, target_attrs = current.to_a, target.to_a
          new_attributes = target_attrs - current_attrs
          removed_attributes = current_attrs - target_attrs

          if current_attrs.empty?
            TableCreated.new(target)
          elsif !new_attributes.empty? || !removed_attributes.empty?
            TableAltered.new(
              target,
              new_attributes: new_attributes,
              removed_attributes: removed_attributes
            )
          else
            Empty.new(target)
          end
        end

        class Diff
          attr_reader :schema

          def initialize(schema)
            @schema = schema
          end

          def empty?
            false
          end

          def apply(gateway)
            raise NotImplementedError
          end
        end

        class Empty < Diff
          def empty?
            true
          end
        end

        class TableCreated < Diff
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

        class TableAltered < Diff
          attr_reader :new_attributes, :removed_attributes

          def initialize(schema, new_attributes: EMPTY_ARRAY, removed_attributes: EMPTY_ARRAY)
            super(schema)

            @new_attributes = new_attributes
            @removed_attributes = removed_attributes
          end

          def apply(gateway)
            new_attributes = self.new_attributes
            removed_attributes = self.removed_attributes

            gateway.connection.alter_table(schema.name.dataset) do
              new_attributes.each do |attribute|
                unwrapped = attribute.optional? ? attribute.right : attribute
                add_column attribute.name, unwrapped.primitive, null: attribute.optional?
              end

              removed_attributes.each do |attribute|
                drop_column attribute.name
              end
            end
          end
        end
      end
    end
  end
end
