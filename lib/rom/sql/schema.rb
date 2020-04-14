# frozen_string_literal: true

require 'rom/schema'

require 'rom/sql/schema/dsl'
require 'rom/sql/order_dsl'
require 'rom/sql/group_dsl'
require 'rom/sql/projection_dsl'
require 'rom/sql/restriction_dsl'
require 'rom/sql/index'
require 'rom/sql/foreign_key'
require 'rom/sql/schema/inferrer'

module ROM
  module SQL
    # Specialized schema for SQL databases
    #
    # @api public
    class Schema < ROM::Schema
      # @!attribute [r] indexes
      #   @return [Array<Index>] Array with schema indexes
      option :indexes, default: -> { EMPTY_SET }

      # @!attribute [r] foreign_keys
      #   @return [Array<ForeignKey>] Array with foreign keys
      option :foreign_keys, default: -> { EMPTY_SET }

      # Open restriction DSL for defining query conditions using schema attributes
      #
      # @see Relation#where
      #
      # @return [Mixed] Result of the block call
      #
      # @api public
      def restriction(&block)
        RestrictionDSL.new(self).call(&block)
      end

      # Open Order DSL for setting ORDER clause in queries
      #
      # @see Relation#order
      #
      # @return [Mixed] Result of the block call
      #
      # @api public
      def order(&block)
        OrderDSL.new(self).call(&block)
      end

      # Open Group DSL for setting GROUP BY clause in queries
      #
      # @see Relation#group
      #
      # @return [Mixed] Result of the block call
      #
      # @api public
      def group(&block)
        GroupDSL.new(self).call(&block)
      end

      # Return a new schema with attributes marked as qualified
      #
      # @return [Schema]
      #
      # @api public
      def qualified(table_alias = nil)
        new(map { |attr| attr.qualified(table_alias) })
      end

      # Return a new schema with attributes that are aliased
      # and marked as qualified
      #
      # Intended to be used when passing attributes to `dataset#select`
      #
      # @return [Schema]
      #
      # @api public
      def qualified_projection(table_alias = nil)
        new(map { |attr| attr.qualified_projection(table_alias) })
      end

      # Project a schema
      #
      # @see ROM::Schema#project
      # @see Relation#select
      #
      # @return [Schema] A new schema with projected attributes
      #
      # @api public
      def project(*names, &block)
        if block
          super(*(names + ProjectionDSL.new(self).(&block)))
        else
          super
        end
      end

      # Project schema so that it only contains primary key
      #
      # @return [Schema]
      #
      # @api private
      def project_pk
        project(*primary_key_names)
      end

      # Project schema so that it only contains renamed foreign key
      #
      # @return [Schema]
      #
      # @api private
      def project_fk(mapping)
        new(rename(mapping).map(&:foreign_key))
      end

      # Join with another schema
      #
      # @param [Schema] other The other schema to join with
      #
      # @return [Schema]
      #
      # @api public
      def join(other)
        merge(other.joined)
      end

      # Return a new schema with all attributes marked as joined
      #
      # @return [Schema]
      #
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
        relation.new(relation.dataset.select(*self.qualified_projection), schema: self)
      end

      # Return an empty schema
      #
      # @return [Schema]
      #
      # @api public
      def empty
        new(EMPTY_ARRAY)
      end

      # Finalize all attributes by qualifying them and initializing primary key names
      #
      # @api private
      def finalize_attributes!(**options)
        super do
          @attributes = map(&:qualified)
        end
      end

      # Finalize associations
      #
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
