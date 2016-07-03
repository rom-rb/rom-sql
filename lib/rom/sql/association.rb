require 'rom/sql/qualified_name'

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
        @source = Relation::Name[source]
        @target = Relation::Name[options[:relation] || target, target]
        @name = self.target.dataset
        super
      end

      def qualify(name, attribute)
        QualifiedName.new(name.dataset, attribute)
      end
    end
  end
end

require 'rom/sql/association/one_to_one'
require 'rom/sql/association/one_to_many'
require 'rom/sql/association/many_to_many'
require 'rom/sql/association/many_to_one'
require 'rom/sql/association/one_to_one_through'
