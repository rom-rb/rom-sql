require 'rom/relation/wrap'

module ROM
  module SQL
    # Specialized wrap relation for SQL
    #
    # This type of relations is returned when using `Relation#wrap` and it uses
    # a join, unlike `Relation#combine`, which means a relation is restricted
    # only to tuples which have associated tuples. It should be used in cases
    # where you want to rely on this restriction.
    #
    # @api public
    class Wrap < Relation::Wrap
      # Return a schema which includes attributes from wrapped relations
      #
      # @return [Schema]
      #
      # @api public
      def schema
        root.schema.merge(nodes.map(&:schema).reduce(:merge)).qualified
      end

      # Internal method used by abstract `ROM::Relation::Wrap`
      #
      # @return [Relation]
      #
      # @api private
      def relation
        relation = nodes.reduce(root) do |a, e|
          if associations.key?(e.name.key)
            a.associations[e.name.key].join(:join, a, e)
          else
            # TODO: deprecate this before 2.0
            a.qualified.join(e.name.dataset, e.meta[:keys])
          end
        end
        schema.(relation)
      end
    end
  end
end
