require 'dry-equalizer'

require 'rom/sql/types'

module ROM
  module SQL
    # Relation schema
    #
    # @api public
    class Schema
      include Dry::Equalizer(:attributes, :meta)
      include Enumerable

      attr_reader :attributes, :meta

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

        # Specify which key(s) should be the primary key
        #
        # @api public
        def primary_key(*names)
          names.each do |name|
            attributes[name] = attributes[name].meta(primary_key: true)
          end
          self
        end

        # @api private
        def call
          Schema.new(attributes)
        end
      end

      # @api private
      def initialize(attributes)
        @attributes = attributes
        freeze
      end

      # Return attribute
      #
      # @api public
      def [](name)
        attributes.fetch(name)
      end

      # @api public
      def primary_key
        attributes.values.select do |attr|
          attr.meta[:primary_key] == true
        end
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
