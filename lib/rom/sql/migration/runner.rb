# frozen_string_literal: true

module ROM
  module SQL
    module Migration
      # @api private
      class Runner
        attr_reader :writer

        def initialize(writer)
          @writer = writer
        end

        def call(changes)
          changes.each { |diff| apply_schema(diff) }
          changes.each { |diff| apply_constraints(diff) }

          self
        end

        def apply_schema(diff)
          case diff
          when SchemaDiff::TableCreated
            create_table(diff)
          when SchemaDiff::TableAltered
            alter_table(diff)
          end
        end

        def apply_constraints(diff)
          case diff
          when SchemaDiff::TableCreated
            alter_foreign_keys(diff, diff.foreign_keys)
          when SchemaDiff::TableAltered
            alter_foreign_keys(diff, diff.foreign_key_changes)
          end
        end

        def create_table(diff)
          writer.migration do |connection|
            connection.create_table(diff.table_name) do
              diff.attributes.each do |attribute|
                if attribute.primary_key?
                  primary_key attribute.name
                else
                  column attribute.name, attribute.type, null: attribute.null?
                end
              end

              diff.indexes.each do |index|
                index index.attributes, index.options
              end
            end
          end
        end

        def alter_table(diff)
          return if diff.meta?

          writer.migration do |connection|
            connection.alter_table(diff.table_name) do
              diff.attribute_changes.each do |attribute|
                case attribute
                when SchemaDiff::AttributeAdded
                  add_column attribute.name, attribute.type, null: attribute.null?
                when SchemaDiff::AttributeRemoved
                  drop_column attribute.name
                when SchemaDiff::AttributeChanged
                  if attribute.type_changed?
                    from, to = attribute.current.unwrap, attribute.target.unwrap
                    raise UnsupportedConversion.new(
                      "Don't know how to convert #{from.inspect} to #{to.inspect}"
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
                  add_index index.attributes, index.options
                when SchemaDiff::IndexRemoved
                  drop_index index.attributes, index.options
                end
              end
            end
          end
        end

        def alter_foreign_keys(diff, foreign_key_changes)
          return if foreign_key_changes.empty?

          writer.migration do |connection|
            connection.alter_table(diff.table_name) do
              foreign_key_changes.map do |fk|
                case fk
                when SchemaDiff::ForeignKeyAdded
                  add_foreign_key fk.child_keys, fk.parent
                when SchemaDiff::ForeignKeyRemoved
                  drop_foreign_key fk.child_keys
                end
              end
            end
          end
        end
      end
    end
  end
end
