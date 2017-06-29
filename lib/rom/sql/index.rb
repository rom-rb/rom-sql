module ROM
  module SQL
    # @api private
    class Index
      extend Initializer
      include Dry::Equalizer(:attributes, :name)

      param :attributes

      option :name, optional: true

      def to_a
        attributes
      end
    end
  end
end
