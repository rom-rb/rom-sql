require 'rom/sql/schema/inferrer'
require 'rom/sql/schema/associations_dsl'

module ROM
  module SQL
    class Schema < ROM::Schema
      class DSL < ROM::Schema::DSL
        attr_reader :associations_dsl

        def associations(&block)
          @associations_dsl = AssociationsDSL.new(name, &block)
        end

        def call
          SQL::Schema.new(
            name,
            attributes,
            associations_dsl && associations_dsl.call,
            inferrer: inferrer && inferrer.new(self))
        end
      end

      def initialize(name, attributes, associations = nil, inferrer: nil)
        @associations = associations
        super(name, attributes, inferrer: inferrer)
      end
    end
  end
end
