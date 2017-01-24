require 'rom/sql/attribute'
require 'rom/sql/schema/inferrer'
require 'rom/sql/schema/associations_dsl'

module ROM
  module SQL
    class Schema < ROM::Schema
      # Extended schema DSL
      #
      # @api private
      class DSL < ROM::Schema::DSL
        attr_reader :associations_dsl

        # Define associations for a relation
        #
        # @example
        #   class Users < ROM::Relation[:sql]
        #     schema(infer: true) do
        #       associations do
        #         has_many :tasks
        #         has_many :posts
        #         has_many :posts, as: :priority_posts, view: :prioritized
        #         belongs_to :account
        #       end
        #     end
        #   end
        #
        #   class Posts < ROM::Relation[:sql]
        #     schema(infer: true) do
        #       associations do
        #         belongs_to :users, as: :author
        #       end
        #     end
        #
        #     view(:prioritized) do
        #       where { priority <= 3 }
        #     end
        #   end
        #
        # @return [AssociationDSL]
        #
        # @api public
        def associations(&block)
          @associations_dsl = AssociationsDSL.new(relation, &block)
        end

        # Return a schema
        #
        # @api private
        def call
          SQL::Schema.define(
            relation, opts.merge(attributes: attributes.values, attr_class: SQL::Attribute)
          )
        end

        private

        # Return schema opts
        #
        # @return [Hash]
        #
        # @api private
        def opts
          opts = { inferrer: inferrer }

          if associations_dsl
            { **opts, associations: associations_dsl.call }
          else
            opts
          end
        end
      end
    end
  end
end
