require 'rom/support/constants'
require 'rom/sql/qualified_attribute'
require 'rom/sql/association/name'

module ROM
  module SQL
    # Abstract association class
    #
    # @api public
    class Association
      include Dry::Equalizer(:source, :target, :result)
      include Options
      extend ClassMacros

      defines :result

      # @!attribute [r] source
      #   @return [ROM::Relation::Name] the source relation name
      attr_reader :source

      # @!attribute [r] target
      #   @return [ROM::Relation::Name] the target relation name
      attr_reader :target

      # @!attribute [r] relation
      #   @return [Symbol] an optional relation identifier for the target
      option :relation, accepts: [Symbol], reader: true

      # @!attribute [r] result
      #   @return [Symbol] either :one or :many
      option :result, accepts: [Symbol], reader: true, default: -> assoc { assoc.class.result }

      # @!attribute [r] as
      #   @return [Symbol] an optional association alias name
      option :as, accepts: [Symbol], reader: true, default: -> assoc { assoc.target.to_sym }

      alias_method :name, :as

      # @api private
      def initialize(source, target, options = EMPTY_HASH)
        @source = Name[source]
        @target = Name[options[:relation] || target, target, options[:as] || target]
        super
      end

      # Returns a qualified attribute name for a given dataset
      #
      # This is compatible with Sequel's SQL generator and can be used in query
      # DSL methods
      #
      # @param name [ROM::Relation::Name]
      # @param attribute [Symbol]
      #
      # @return [QualifiedAttribute]
      #
      # @api public
      def qualify(name, attribute)
        QualifiedAttribute[name.dataset, attribute]
      end

      protected

      # @api private
      def join_key_map(relations)
        join_keys(relations).to_a.flatten.map(&:to_sym)
      end
    end
  end
end

require 'rom/sql/association/one_to_many'
require 'rom/sql/association/one_to_one'
require 'rom/sql/association/many_to_many'
require 'rom/sql/association/many_to_one'
require 'rom/sql/association/one_to_one_through'
