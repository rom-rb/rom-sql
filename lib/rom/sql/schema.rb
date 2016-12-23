require 'rom/schema'

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

      def initialize(*)
        super
        @primary_key_name = nil
        @primary_key_names = EMPTY_ARRAY
      end

      # Return a new schema with attributes marked as qualified
      #
      # @return [Schema]
      #
      # @api public
      def qualified
        new(map { |attr| [attr.name, attr.qualified] }.to_h)
      end

      # Create a new relation based on the schema definition
      #
      # @param [Relation] relation The source relation
      #
      # @return [Relation]
      #
      # @api public
      def call(relation)
        relation.select(*self).with(schema: self)
      end

      # @api private
      def finalize!(*)
        super do
          if primary_key.size > 0
            @primary_key_name = primary_key[0].meta[:name]
            @primary_key_names = primary_key.map { |type| type.meta[:name] }
          end
        end
      end
    end
  end
end

require 'rom/sql/schema/dsl'
