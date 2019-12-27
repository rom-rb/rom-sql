# frozen_string_literal: true

module ROM
  module SQL
    # @api private
    class Index
      extend Initializer
      include Dry::Equalizer(:attributes, :name)

      param :attributes

      option :name, optional: true

      option :unique, default: -> { false }

      alias_method :unique?, :unique

      option :type, optional: true

      option :predicate, optional: true

      def to_a
        attributes
      end

      def partial?
        !predicate.nil?
      end

      def can_access?(attribute)
        !partial? && attributes[0].name == attribute.name
      end
    end
  end
end
