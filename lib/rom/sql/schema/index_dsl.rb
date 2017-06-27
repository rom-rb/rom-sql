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

        # @api public
        def index(*attributes, **options)
          registry << [attributes, options]
        end

        # @api private
        def call(types)
          attributes = types.map { |type| attr_class.new(type) }

          registry.map { |attr_names, options|
            build_index(attributes, attr_names, options)
          }.to_set
        end

        private

        # @api private
        def build_index(attributes, attr_names, _options)
          index_attributes = attr_names.map do |name|
            attributes.find { |a| a.name == name }
          end

          Index.new(index_attributes)
        end
      end
    end
  end
end
