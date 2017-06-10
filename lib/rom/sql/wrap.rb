require 'rom/relation/wrap'

module ROM
  module SQL
    class Wrap < Relation::Wrap
      # @api public
      def schema
        root.schema.merge(nodes.map(&:schema).reduce(:merge)).qualified
      end

      # @api private
      def relation
        relation = nodes.reduce(root) do |a, e|
          if associations.key?(e.name.key)
            a.associations[e.name.key].join(__registry__, :inner_join, a, e)
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
