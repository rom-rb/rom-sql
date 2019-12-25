# frozen_string_literal: true

require 'set'

module ROM
  module SQL
    class Schema < ROM::Schema
      # @api public
      class IndexDSL # < BasicObject
        extend Initializer

        option :attr_class

        attr_reader :registry

        # @api private
        def initialize(*, &block)
          super

          @registry = []

          instance_exec(&block)
        end
        ruby2_keywords(:initialize) if respond_to?(:ruby2_keywords, true)

        # @api public
        def index(*attributes, **options)
          registry << [attributes, options]
        end

        # @api private
        def call(schema_name, attrs)
          attributes = attrs.map do |attr|
            attr_class.new(attr[:type], **(attr[:options] || {})).meta(source: schema_name)
          end

          registry.map { |attr_names, options|
            build_index(attributes, attr_names, options)
          }.to_set
        end

        private

        # @api private
        def build_index(attributes, attr_names, options)
          index_attributes = attr_names.map do |name|
            attributes.find { |a| a.name == name }.unwrap
          end

          Index.new(index_attributes, **options)
        end
      end
    end
  end
end
