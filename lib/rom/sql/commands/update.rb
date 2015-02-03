require 'rom/sql/commands'

module ROM
  module SQL
    module Commands
      class Update < ROM::Commands::Update
        include TupleCount

        def execute(tuple)
          attributes = input[tuple]
          validator.call(attributes)

          pks = relation.map { |t| t[relation.model.primary_key] }

          relation.update(attributes.to_h)
          relation.unfiltered.where(relation.model.primary_key => pks)
        end
      end
    end
  end
end
