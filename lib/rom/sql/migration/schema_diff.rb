module ROM
  module SQL
    module Migration
      class SchemaDiff
        def self.compare(current, target)
          current_attrs, target_attrs = current.to_a, target.to_a
          added_attributes = target_attrs - current_attrs
          removed_attributes = current_attrs - target_attrs

          if current_attrs.empty?
            TableCreated.new(target)
          elsif !added_attributes.empty? || !removed_attributes.empty?
            TableAltered.new(
              target,
              added_attributes: added_attributes,
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

          def table_name
            schema.name.dataset
          end
        end

        class Empty < Diff
          def empty?
            true
          end
        end

        class TableCreated < Diff
        end

        class TableAltered < Diff
          attr_reader :added_attributes, :removed_attributes

          def initialize(schema, added_attributes: EMPTY_ARRAY, removed_attributes: EMPTY_ARRAY)
            super(schema)

            @added_attributes = added_attributes
            @removed_attributes = removed_attributes
          end
        end
      end
    end
  end
end
