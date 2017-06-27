require 'rom/schema'

require 'rom/sql/schema/dsl'
require 'rom/sql/order_dsl'
require 'rom/sql/group_dsl'
require 'rom/sql/projection_dsl'
require 'rom/sql/restriction_dsl'
require 'rom/sql/index'
require 'rom/sql/schema/inferrer'

module ROM
  module SQL
    class Schema < ROM::Schema
      # @!attribute [r] attributes
      #   @return [Array<Index>] Array with schema indexes
      option :indexes, default: -> { EMPTY_SET }

      # @api public
      def restriction(&block)
        RestrictionDSL.new(self).call(&block)
      end

      # @api public
      def order(&block)
        OrderDSL.new(self).call(&block)
      end

      # @api public
      def group(&block)
        GroupDSL.new(self).call(&block)
      end

      # Return a new schema with attributes marked as qualified
      #
      # @return [Schema]
      #
      # @api public
      def qualified
        new(map(&:qualified))
      end

      # Return a new schema with attributes restored to canonical form
      #
      # @return [Schema]
      #
      # @api public
      def canonical
        new(map(&:canonical))
      end

      # @api public
      def project(*names, &block)
        if block
          super(*(names + ProjectionDSL.new(self).(&block)))
        else
          super
        end
      end

      # @api private
      def project_pk
        project(*primary_key_names)
      end

      # @api private
      def project_fk(mapping)
        new(rename(mapping).map(&:foreign_key))
      end

      # @api public
      def join(other)
        merge(other.joined)
      end

      # @api public
      def joined
        new(map(&:joined))
      end

      # Create a new relation based on the schema definition
      #
      # @param [Relation] relation The source relation
      #
      # @return [Relation]
      #
      # @api public
      def call(relation)
        relation.new(relation.dataset.select(*self), schema: self)
      end

      # Return an empty schema
      #
      # @return [Schema]
      #
      # @api public
      def empty
        new(EMPTY_ARRAY)
      end

      # @api private
      def finalize_attributes!(options = EMPTY_HASH)
        super do
          initialize_primary_key_names
        end
      end

      # @api private
      def finalize_associations!(relations:)
        super do
          associations.map do |definition|
            SQL::Associations.const_get(definition.type).new(definition, relations)
          end
        end
      end

      memoize :qualified, :canonical, :joined, :project_pk
    end
  end
end
