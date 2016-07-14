require 'rom/schema'

module ROM
  module SQL
    class Schema < ROM::Schema
      include Dry::Equalizer(:name, :attributes, :associations)

      attr_reader :associations

      def initialize(name, attributes, associations = nil, inferrer: nil)
        @associations = associations
        super(name, attributes, inferrer: inferrer)
      end
    end
  end
end

require 'rom/sql/schema/dsl'
