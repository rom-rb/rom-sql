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

      def to_a
        attributes
      end
    end
  end
end
