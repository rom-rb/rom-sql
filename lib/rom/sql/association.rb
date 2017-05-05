require 'dry/core/constants'
require 'dry/core/class_attributes'

require 'rom/types'
require 'rom/initializer'
require 'rom/sql/qualified_attribute'
require 'rom/sql/association/name'

module ROM
  module SQL
    # Abstract association class
    #
    # @api public
    class Association
      include Dry::Core::Constants
      include Dry::Equalizer(:source, :target, :result)
      extend Initializer
      extend Dry::Core::ClassAttributes

      defines :result

      # @!attribute [r] source
      #   @return [ROM::Relation::Name] the source relation name
      param :source

      # @!attribute [r] target
      #   @return [ROM::Relation::Name] the target relation name
      param :target

      # @!attribute [r] relation
      #   @return [Symbol] an optional relation identifier for the target
      option :relation, Types::Strict::Symbol, optional: true

      # @!attribute [r] result
      #   @return [Symbol] either :one or :many
      option :result, Types::Strict::Symbol, default: -> { self.class.result }

      # @!attribute [r] as
      #   @return [Symbol] an optional association alias name
      option :as, Types::Strict::Symbol, default: -> { target.to_sym }

      # @!attribute [r] foreign_key
      #   @return [Symbol] an optional association alias name
      option :foreign_key, Types::Optional::Strict::Symbol, optional: true

      # @!attribute [r] view
      #   @return [Symbol] An optional view that should be used to extend assoc relation
      option :view, optional: true

      alias_method :name, :as

      # @api public
      def self.new(source, target, options = EMPTY_HASH)
        super(
          Name[source],
          Name[options[:relation] || target, target, options[:as] || target],
          options
        )
      end

      # @api public
      def join(relations, type, source = relations[self.source], target = relations[self.target])
        source.__send__(type, target.name.dataset, join_keys(relations)).qualified
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
        QualifiedAttribute[name.to_sym, attribute]
      end

      # @api protected
      def apply_view(schema, relation)
        view_rel = relation.public_send(view)
        schema.merge(view_rel.schema.qualified).uniq(&:to_sql_name).(view_rel)
      end

      # @api private
      def join_key_map(relations)
        join_keys(relations).to_a.flatten.map(&:to_sym)
      end

      def self_ref?
        source.dataset == target.dataset
      end
    end
  end
end

require 'rom/sql/association/one_to_many'
require 'rom/sql/association/one_to_one'
require 'rom/sql/association/many_to_many'
require 'rom/sql/association/many_to_one'
require 'rom/sql/association/one_to_one_through'
