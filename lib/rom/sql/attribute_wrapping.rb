# frozen_string_literal: true

module ROM
  module SQL
    # @api private
    module AttributeWrapping
      # Return if the attribute type is from a wrapped relation
      #
      # Wrapped attributes are used when two schemas from different relations
      # are merged together. This way we can identify them easily and handle
      # correctly in places like auto-mapping.
      #
      # @api public
      def wrapped?
        !meta[:wrapped].nil?
      end

      # Return attribute type wrapped for the specified relation name
      #
      # @param [Symbol] name The name of the source relation (defaults to source.dataset)
      #
      # @return [Attribute]
      #
      # @api public
      def wrapped(name = source.dataset)
        meta(wrapped: name).prefixed(name)
      end
    end
  end
end
