module ROM
  module SQL
    class Association
      include Dry::Equalizer(:source, :target, :options)
      include Options
      extend ClassMacros

      defines :result

      attr_reader :source
      attr_reader :target
      attr_reader :name

      option :relation, accepts: [Symbol], reader: true
      option :result, accepts: [Symbol], reader: true, default: -> assoc { assoc.class.result }

      def initialize(source, target, options = {})
        @source = source
        @target = options[:relation] || target
        @name = target
        super
      end
    end
  end
end

require 'rom/sql/association/one_to_one'
require 'rom/sql/association/one_to_many'
require 'rom/sql/association/many_to_many'
require 'rom/sql/association/many_to_one'
require 'rom/sql/association/one_to_one_through'
