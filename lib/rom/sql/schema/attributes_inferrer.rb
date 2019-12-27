# frozen_string_literal: true

require 'dry/core/class_attributes'

module ROM
  module SQL
    class Schema < ROM::Schema
      # @api private
      class AttributesInferrer
        extend Dry::Core::ClassAttributes
        extend Initializer

        defines :type_builders

        CONSTRAINT_DB_TYPE = 'add_constraint'.freeze

        option :type_builder

        option :attr_class, optional: true

        # @api private
        def call(schema, gateway)
          dataset = schema.name.dataset

          columns = filter_columns(gateway.connection.schema(dataset))

          inferred = columns.map do |name, definition|
            type = type_builder.(**definition)

            attr_class.new(type.meta(source: schema.name), name: name) if type
          end.compact

          missing = columns.map(&:first) - inferred.map { |attr| attr.name }

          [inferred, missing]
        end

        undef :with

        # @api private
        def with(new_options)
          self.class.new(options.merge(new_options))
        end

        # @api private
        def filter_columns(schema)
          schema.reject { |_, definition| definition[:db_type] == CONSTRAINT_DB_TYPE }
        end
      end
    end
  end
end
