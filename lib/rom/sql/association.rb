module ROM
  module SQL
    class Association
      include Dry::Equalizer(:source, :target, :options)
      include Options

      attr_reader :source
      attr_reader :target

      def initialize(source, target, options = {})
        @source = source
        @target = target
        super
      end

      class ManyToMany < Association
        option :through, reader: true, default: nil, accepts: [Symbol]
      end
    end
  end
end
