# frozen_string_literal: true

require 'rom/sql/type_serializer'

module ROM
  module SQL
    module Migration
      # @api private
      class SchemaDiff
        extend Initializer

        param :database_type

        option :type_serializer, default: -> { ROM::SQL::TypeSerializer[database_type] }

        class TableDiff
          extend Initializer

          option :current_schema, optional: true

          option :target_schema, optional: true

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

          option :attributes

          option :indexes, default: -> { EMPTY_ARRAY }

          option :foreign_keys, default: -> { EMPTY_ARRAY }
        end

        class TableAltered < TableDiff

          option :attribute_changes, default: -> { EMPTY_ARRAY }

          option :index_changes, default: -> { EMPTY_ARRAY }

          option :foreign_key_changes, default: -> { EMPTY_ARRAY }

          def meta?
            attribute_changes.empty? && index_changes.empty?
          end
        end

        class AttributeDiff
          extend Initializer

          param :attr

          option :type_serializer

          def name
            attr.name
          end

          def null?
            attr.optional?
          end

          def primary_key?
            attr.primary_key?
          end

          def unwrap(attr)
            attr.optional? ? SQL::Attribute[attr.right, attr.options].meta(attr.meta) : attr
          end
        end

        class AttributeAdded < AttributeDiff
          def type
            type_serializer.(unwrap(attr).type)
          end
        end

        class AttributeRemoved < AttributeDiff
        end

        class AttributeChanged < AttributeDiff
          param :current
          alias_method :target, :attr

          def nullability_changed?
            current.optional? ^ target.optional?
          end

          def type_changed?
            clean(current.qualified) != clean(target.qualified)
          end

          private

          def clean(type)
            unwrap(type).meta(index: nil, foreign_key: nil, target: nil)
          end
        end

        class IndexDiff
          attr_reader :index

          def initialize(index)
            @index = index
          end

          def attributes
            list = index.attributes.map(&:name)

            if list.size == 1
              list[0]
            else
              list
            end
          end

          def name
            index.name
          end
        end

        class IndexAdded < IndexDiff
          def options
            options = {}
            options[:name] = index.name if !index.name.nil?
            options[:unique] = true if index.unique?
            options[:type] = index.type if !index.type.nil?
            options[:where] = index.predicate if !index.predicate.nil?
            options
          end
        end

        class IndexRemoved < IndexDiff
          def options
            options = {}
            options[:name] = index.name if !index.name.nil?
            options
          end
        end

        class ForeignKeyDiff
          attr_reader :foreign_key

          def initialize(foreign_key)
            @foreign_key = foreign_key
          end

          def parent
            foreign_key.parent_table
          end

          def parent_keys
            foreign_key.parent_keys
          end

          def child_keys
            foreign_key.attributes.map(&:name)
          end
        end

        class ForeignKeyAdded < ForeignKeyDiff
        end

        class ForeignKeyRemoved < ForeignKeyDiff
        end

        def call(current, target)
          if current.empty?
            TableCreated.new(
              target_schema: target,
              attributes: map_attributes(target.to_h, AttributeAdded),
              indexes: target.indexes.map { |idx| IndexAdded.new(idx) },
              foreign_keys: target.foreign_keys.map { |fk| ForeignKeyAdded.new(fk) }
            )
          else
            attribute_changes = compare_attributes(current.to_h, target.to_h)
            index_changes = compare_indexes(current, target)
            fk_changes = compare_foreign_key_constraints(current, target)

            if attribute_changes.empty? && index_changes.empty? && fk_changes.empty?
              Empty.new(current_schema: current, target_schema: target)
            else
              TableAltered.new(
                current_schema: current,
                target_schema: target,
                attribute_changes: attribute_changes,
                index_changes: index_changes,
                foreign_key_changes: fk_changes
              )
            end
          end
        end

        def compare_attributes(current, target)
          changed_attributes = target.select { |name, attr|
            current.key?(name) && !attributes_equal?(current[name], attr)
          }.map { |name, target_attr|
            [name, [target_attr, current[name]]]
          }.to_h
          added_attributes = target.select { |name, _| !current.key?(name) }
          removed_attributes = current.select { |name, _| !target.key?(name) }

          map_attributes(removed_attributes, AttributeRemoved) +
            map_attributes(added_attributes, AttributeAdded) +
            map_attributes(changed_attributes, AttributeChanged)
        end

        def compare_indexes(current, target)
          added_indexes = target.indexes.reject { |idx|
            current.indexes.any? { |curr_idx| curr_idx.attributes == idx.attributes }
          }
          removed_indexes = current.indexes.select { |idx|
            target.indexes.none? { |tgt_idx| idx.attributes == tgt_idx.attributes }
          }

          removed_indexes.map { |idx| IndexRemoved.new(idx) } +
            added_indexes.map { |idx| IndexAdded.new(idx) }
        end

        def compare_foreign_key_constraints(current, target)
          target_fks = target.foreign_keys
          current_fks = current.foreign_keys

          added_fks = target_fks - current_fks
          removed_fks = current_fks - target_fks

          removed_fks.map { |fk| ForeignKeyRemoved.new(fk) } +
            added_fks.map { |fk| ForeignKeyAdded.new(fk) }
        end

        def attributes_equal?(a, b)
          a.qualified == b.qualified
        end

        def map_attributes(attributes, change_type)
          attributes.values.map { |args| change_type.new(*args, type_serializer: type_serializer) }
        end
      end
    end
  end
end
