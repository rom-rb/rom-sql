require 'rom/schema'
require 'rom/sql/projection_dsl'
require 'rom/sql/restriction_dsl'

module ROM
  module SQL
    class Schema < ROM::Schema
      # @!attribute [r] primary_key_name
      #   @return [Symbol] The name of the primary key. This is set because in
      #                    most of the cases relations don't have composite pks
      attr_reader :primary_key_name

      # @!attribute [r] primary_key_names
      #   @return [Array<Symbol>] A list of all pk names
      attr_reader :primary_key_names

      # @api private
      def initialize(*)
        super
        initialize_primary_key_names
      end

      # @api public
      def restriction(&block)
        RestrictionDSL.new(self).call(&block)
      end

      # Return a new schema with attributes marked as qualified
      #
      # @return [Schema]
      #
      # @api public
      def qualified
        new(map(&:qualified))
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
      def join(name)
        schema = relations.detect(method(:join_table_not_found)) { |_, r|
          r.schema.name.dataset == name.to_sym
        }[1].schema

        merge(schema.joined)
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

      # @api private
      def finalize!(*)
        super do
          initialize_primary_key_names
        end
      end

      # @api private
      def initialize_primary_key_names
        if primary_key.size > 0
          @primary_key_name = primary_key[0].meta[:name]
          @primary_key_names = primary_key.map { |type| type.meta[:name] }
        end
      end

      private

      def join_table_not_found
        raise ROM::SQL::Error, "can't join with '#{name}'; table not found"
      end
    end
  end
end

require 'rom/sql/schema/dsl'
