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

      # @api public
      def project_relation(relation)
        relation.select(*attributes.keys)
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
