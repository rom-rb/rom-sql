module ROM
  module SQL
    module Migration
      class SchemaDiff
        def self.compare(current, target)
          if current.empty?
            TableCreated.new(target_schema: target)
          else
            current_attrs, target_attrs = current.to_h, target.to_h

            changed_attributes = target_attrs.select { |name, attr|
              current_attrs.key?(name) && current_attrs[name] != attr
            }.map { |name, target_attr|
              [name, [current_attrs[name], target_attr]]
            }.to_h
            added_attributes = target_attrs.select { |name, _| !current_attrs.key?(name) }
            removed_attributes = current_attrs.select { |name, _| !target_attrs.key?(name) }

            if [changed_attributes, added_attributes, removed_attributes].all?(&:empty?)
              Empty.new(current_schema: current, target_schema: target)
            else
              TableAltered.new(
                current_schema: current,
                target_schema: target,
                added: added_attributes,
                removed: removed_attributes,
                changed: changed_attributes
              )
            end
          end
        end

        class Diff
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

        class Empty < Diff
          def empty?
            true
          end
        end

        class TableCreated < Diff
          alias_method :schema, :target_schema
        end

        class TableAltered < Diff
          attr_reader :added, :changed, :removed

          def initialize(added: EMPTY_HASH, removed: EMPTY_HASH, changed: EMPTY_HASH, **rest)
            super(rest)

            @added = added
            @removed = removed
            @changed = changed
          end
        end
      end
    end
  end
end
