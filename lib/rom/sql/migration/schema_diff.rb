module ROM
  module SQL
    module Migration
      class SchemaDiff
        class TableDiff
          attr_reader :current_schema, :target_schema

          def initialize(current_schema: nil, target_schema: nil)
            @current_schema = current_schema
            @target_schema = target_schema
          end

          def empty?
            false
          end

          def table_name
            target_schema.name.dataset
          end
        end

        class Empty < TableDiff
          def empty?
            true
          end
        end

        class TableCreated < TableDiff
          alias_method :schema, :target_schema
          attr_reader :attributes, :indexes

          def initialize(attributes:, indexes: EMPTY_ARRAY, **rest)
            super(rest)

            @attributes = attributes
            @indexes = indexes
          end
        end

        class TableAltered < TableDiff
          attr_reader :attribute_changes, :index_changes

          def initialize(attribute_changes: EMPTY_ARRAY, index_changes: EMPTY_ARRAY, **rest)
            super(rest)

            @attribute_changes = attribute_changes
            @index_changes = index_changes
          end
        end

        class AttributeDiff
          attr_reader :attr

          def initialize(attr)
            @attr = attr
          end

          def name
            attr.name
          end

          def null?
            attr.optional?
          end

          def primary_key?
            attr.primary_key?
          end

          def unwrap(type)
            type.optional? ? SQL::Attribute[type.right].meta(type.meta) : type
          end
        end

        class AttributeAdded < AttributeDiff
          def type
            unwrap(attr).primitive
          end
        end

        class AttributeRemoved < AttributeDiff
        end

        class AttributeChanged < AttributeDiff
          attr_reader :current
          alias_method :target, :attr

          def initialize(current, target)
            super(target)

            @current = current
          end

          def to_a
            [current, target]
          end

          def nullability_changed?
            current.optional? ^ target.optional?
          end

          def type_changed?
            unwrap(current).meta(index: Set.new) != unwrap(target).meta(index: Set.new)
          end
        end

        class IndexDiff
          attr_reader :index

          def initialize(index)
            @index = index
          end

          def attribute
            index.attributes[0].name
          end

          def name
            index.name
          end
        end

        class IndexAdded < IndexDiff
        end

        class IndexRemoved < IndexDiff
        end

        def call(current, target)
          if current.empty?
            TableCreated.new(
              target_schema: target,
              attributes: target.map { |attr| AttributeAdded.new(attr) },
              indexes: target.indexes.map { |idx| IndexAdded.new(idx) }
            )
          else
            attribute_changes = compare_attributes(current.to_h, target.to_h)
            index_changes = compare_indexes(current, target)

            if attribute_changes.empty? && index_changes.empty?
              Empty.new(current_schema: current, target_schema: target)
            else
              TableAltered.new(
                current_schema: current,
                target_schema: target,
                attribute_changes: attribute_changes,
                index_changes: index_changes
              )
            end
          end
        end

        def compare_attributes(current, target)
          changed_attributes = target.select { |name, attr|
            current.key?(name) && current[name] != attr
          }.map { |name, target_attr|
            [name, [current[name], target_attr]]
          }.to_h
          added_attributes = target.select { |name, _| !current.key?(name) }
          removed_attributes = current.select { |name, _| !target.key?(name) }

          removed_attributes.values.map { |attr| AttributeRemoved.new(attr) } +
            added_attributes.values.map { |attr| AttributeAdded.new(attr) } +
            changed_attributes.values.map { |attrs| AttributeChanged.new(*attrs) }
        end

        def compare_indexes(current, target)
          added_indexes = target.indexes.reject { |idx|
            current.indexes.any? { |curr_idx| curr_idx.attributes == idx.attributes }
          }
          removed_indexes = current.indexes.select { |idx|
            target.indexes.none? { |tgt_idx| idx.attributes == tgt_idx  }
          }

          removed_indexes.map { |idx| IndexRemoved.new(idx) } +
            added_indexes.map { |idx| IndexAdded.new(idx) }
        end
      end
    end
  end
end
