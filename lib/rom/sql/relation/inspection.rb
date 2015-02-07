module ROM
  module SQL
    class Relation < ROM::Relation
      module Inspection
        def exposed_relations
          super + (dataset.public_methods & public_methods) -
            Object.public_instance_methods -
            ROM::Relation.public_instance_methods -
            SQL::Relation.public_instance_methods
        end

        def model
          self.class.model
        end

        # @api private
        def primary_key
          model.primary_key
        end
      end
    end
  end
end
