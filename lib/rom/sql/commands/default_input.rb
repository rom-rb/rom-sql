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
          super(relation, options.merge(input: default_input(relation)))
        end

        # @api private
        def default_input(relation)
          schema = relation.class.schema

          if relation.class.schema
            Types::Hash.schema(schema)
          else
            Hash
          end
        end
      end
    end
  end
end
