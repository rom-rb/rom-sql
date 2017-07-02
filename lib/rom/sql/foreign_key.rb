module ROM
  module SQL
    # @api private
    class ForeignKey
      extend Initializer
      include Dry::Equalizer(:source_attributes, :target_attributes)

      param :source_attributes

      param :target_attributes

      option :name, optional: true

      def source
        source_attributes[0].source
      end

      def target
        target_attributes[0].source
      end
    end
  end
end
