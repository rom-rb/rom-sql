require 'rom/sql/qualified_name'
require 'rom/sql/association/name'

module ROM
  module SQL
    class Association
      include Dry::Equalizer(:source, :target, :options)
      include Options
      extend ClassMacros

      defines :result

      attr_reader :source
      attr_reader :target

      option :relation, accepts: [Symbol], reader: true
      option :result, accepts: [Symbol], reader: true, default: -> assoc { assoc.class.result }
      option :as, accepts: [Symbol], reader: true, default: -> assoc { assoc.target.to_sym }

      alias_method :name, :as

      def initialize(source, target, options = {})
        @source = Name[source]
        @target = Name[options[:relation] || target, target, options[:as] || target]
        super
      end

      def join_key_map(relations)
        join_keys(relations).to_a.flatten.map(&:to_sym)
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
