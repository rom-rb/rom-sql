require 'set'

require 'rom/sql/schema/attributes_inferrer'
require 'rom/sql/attribute'

module ROM
  module SQL
    class Schema < ROM::Schema
      # @api private
      class Inferrer < ROM::Schema::Inferrer
        attributes_inferrer -> (schema, gateway, options) do
          AttributesInferrer.get(gateway.database_type).with(options).(schema, gateway)
        end

        attr_class SQL::Attribute

        option :silent, default: -> { false }

        option :raise_on_error, default: -> { true }

        FALLBACK_SCHEMA = { attributes: EMPTY_ARRAY, indexes: EMPTY_SET }.freeze

        # @api private
        def call(schema, gateway)
          inferred = super

          indexes = get_indexes(gateway, schema, inferred[:attributes])

          { **inferred, indexes: indexes }
        rescue Sequel::Error => error
          on_error(schema.name, error)
          FALLBACK_SCHEMA
        end

        # @api private
        def get_indexes(gateway, schema, attributes)
          dataset = schema.name.dataset

          if enabled? && gateway.connection.respond_to?(:indexes)
            gateway.connection.indexes(dataset).map { |name, body|
              columns = body[:columns].map { |name|
                attributes.find { |attr| attr.name == name }
              }

              SQL::Index.new(columns, name: name)
            }.to_set
          else
            schema.indexes | indexes_from_attributes(attributes)
          end
        end

        def indexes_from_attributes(attributes)
          attributes.select(&:indexed?).map { |attr| SQL::Index.new([attr]) }.to_set
        end

        # @api private
        def suppress_errors
          with(raise_on_error: false, silent: true)
        end

        private

        # @api private
        def on_error(dataset, e)
          if raise_on_error
            raise e
          elsif !silent
            warn "[#{dataset}] failed to infer schema. " \
                 "Make sure tables exist before ROM container is set up. " \
                 "This may also happen when your migration tasks load ROM container, " \
                 "which is not needed for migrations as only the connection is required " \
                 "(#{e.message})"
          end
        end
      end
    end
  end
end
