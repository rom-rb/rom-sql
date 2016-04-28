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
    end
  end
end

require 'rom/sql/association/one_to_one'
require 'rom/sql/association/one_to_many'
require 'rom/sql/association/one_to_one_through'
require 'rom/sql/association/many_to_many'
require 'rom/sql/association/many_to_one'
