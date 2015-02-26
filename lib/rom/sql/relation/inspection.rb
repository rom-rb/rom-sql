module ROM
  module SQL
    class Relation < ROM::Relation
      module Inspection
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
