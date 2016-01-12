require 'dry-equalizer'

require 'rom/sql/types'

module ROM
  module SQL
    class Schema
      include Dry::Equalizer(:attributes)
      include Enumerable

      attr_reader :attributes

      class DSL < BasicObject
        attr_reader :attributes

        def initialize(&block)
          @attributes = {}
          instance_exec(&block)
        end

        def attribute(name, type)
          @attributes[name] = type
        end

        def call
          Schema.new(attributes)
        end
      end

      def initialize(attributes = {})
        @attributes = attributes
        freeze
      end

      def each(&block)
        attributes.each(&block)
      end
    end
  end
end
