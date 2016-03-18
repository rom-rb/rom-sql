module ROM
  module SQL
    module Commands
      # @api private
      module DefaultInput
        # Builds a command and creates a default input handler from a relation
        # schema
        #
        # @api public
        def build(relation, options = {})
          input_processor =
            if relation.schema?
              Types::Hash.schema(relation.schema)
            else
              input
            end

          super(relation, options.merge(input: input_processor))
        end
      end
    end
  end
end
