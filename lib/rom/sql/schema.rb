require 'dry-equalizer'

require 'rom/sql/types'

module ROM
  module SQL
    # Relation schema
    #
    # @api public
    class Schema
      include Dry::Equalizer(:attributes)
      include Enumerable

      attr_reader :attributes

      # @api public
      class DSL < BasicObject
        attr_reader :attributes

        # @api private
        def initialize(&block)
          @attributes = {}
          instance_exec(&block)
        end

        # Defines a relation attribute with its type
        #
        # @see Relation.schema
        #
        # @api public
        def attribute(name, type)
          @attributes[name] = type
        end

        # @api private
        def call
          Schema.new(attributes)
        end
      end

      # @api private
      def initialize(attributes = {})
        @attributes = attributes
        freeze
      end

      # Iterate over schema's attributes
      #
      # @yield [Dry::Data::Type]
      #
      # @api public
      def each(&block)
        attributes.each(&block)
      end
    end
  end
end
