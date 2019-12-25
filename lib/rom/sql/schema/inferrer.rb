# frozen_string_literal: true

require 'set'

require 'rom/sql/schema/type_builder'
require 'rom/sql/schema/attributes_inferrer'
require 'rom/sql/attribute'

module ROM
  module SQL
    class Schema < ROM::Schema
      # @api private
      class Inferrer < ROM::Schema::Inferrer
        defines :type_builders

        attributes_inferrer -> (schema, gateway, options) do
          builder = TypeBuilder[gateway.database_type]
          inferrer = AttributesInferrer.new(type_builder: builder, **options)
          inferrer.(schema, gateway)
        end

        attr_class SQL::Attribute

        option :silent, default: -> { false }

        option :raise_on_error, default: -> { true }

        FALLBACK_SCHEMA = {
          attributes: EMPTY_ARRAY,
          indexes: EMPTY_SET,
          foreign_keys: EMPTY_SET
        }.freeze

        # @api private
        def call(schema, gateway)
          if enabled?
            infer_from_database(gateway, schema, **super)
          else
            infer_from_attributes(gateway, schema, **super)
          end
        rescue Sequel::Error => error
          on_error(schema.name, error)
          { **FALLBACK_SCHEMA, indexes: schema.indexes }
        end

        # @api private
        def infer_from_database(gateway, schema, attributes:, **rest)
          idx = attributes_index(attributes)
          indexes = indexes_from_database(gateway, schema, idx)
          foreign_keys = foreign_keys_from_database(gateway, schema, idx)

          { **rest,
            attributes: attributes.map { |attr| mark_fk(mark_indexed(attr, indexes), foreign_keys) },
            foreign_keys: foreign_keys,
            indexes: indexes }
        end

        # @api private
        def infer_from_attributes(_gateway, schema, attributes:, **rest)
          indexes = schema.indexes | indexes_from_attributes(attributes)
          foreign_keys = foreign_keys_from_attributes(attributes)

          { **rest,
            attributes: attributes.map { |attr| mark_indexed(attr, indexes) },
            foreign_keys: foreign_keys,
            indexes: indexes }
        end

        # @api private
        def indexes_from_database(gateway, schema, attributes)
          if gateway.connection.respond_to?(:indexes)
            dataset = schema.name.dataset

            gateway.connection.indexes(dataset).map { |index_name, definition|
              columns, unique = definition.values_at(:columns, :unique)
              attrs = columns.map { |name| attributes[name] }

              SQL::Index.new(attrs, name: index_name, unique: unique)
            }.to_set
          else
            EMPTY_SET
          end
        end

        # @api private
        def foreign_keys_from_database(gateway, schema, attributes)
          dataset = schema.name.dataset

          gateway.connection.foreign_key_list(dataset).map { |definition|
            columns, table, key = definition.values_at(:columns, :table, :key)
            attrs = columns.map { |name| attributes[name] }

            SQL::ForeignKey.new(attrs, table, parent_keys: key)
          }.to_set
        end

        # @api private
        def indexes_from_attributes(attributes)
          attributes.
            select(&:indexed?).
            map { |attr| SQL::Index.new([attr.unwrap]) }.
            to_set
        end

        # @api private
        def foreign_keys_from_attributes(attributes)
          attributes.
            select(&:foreign_key?).
            map { |attr| SQL::ForeignKey.new([attr.unwrap], attr.target) }.
            to_set
        end

        # @api private
        def suppress_errors
          with(raise_on_error: false, silent: true)
        end

        private

        def attributes_index(attributes)
          Hash.new { |idx, name| idx[name] = attributes.find { |attr| attr.name == name }.unwrap }
        end

        # @private
        def mark_indexed(attribute, indexes)
          if !attribute.indexed? && indexes.any? { |index| index.can_access?(attribute) }
            attribute.indexed
          else
            attribute
          end
        end

        # @private
        def mark_fk(attribute, foreign_keys)
          if attribute.foreign_key?
            attribute
          else
            foreign_key = foreign_keys.find { |fk| fk.attributes.map(&:name) == [attribute.name] }

            if foreign_key.nil?
              attribute
            else
              attribute.meta(foreign_key: true, target: foreign_key.parent_table)
            end
          end
        end

        # @api private
        def on_error(dataset, e)
          if raise_on_error
            raise e
          elsif !silent
            warn "[#{dataset}] failed to infer schema. " \
                 'Make sure tables exist before ROM container is set up. ' \
                 'This may also happen when your migration tasks load ROM container, ' \
                 'which is not needed for migrations as only the connection is required ' \
                 "(#{e.message})"
          end
        end
      end
    end
  end
end
