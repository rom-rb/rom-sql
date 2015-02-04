require 'rom/sql/commands/create'

module ROM
  module SQL
    module Commands
      module Postgres
        class Create < Commands::Create
          def insert(tuples)
            pk = Array(relation.model.primary_key)
            keys = nil

            tuples.map do |tuple|
              keys ||= pk + tuple.keys
              relation.dataset.returning(*keys).insert(tuple)
            end.flatten
          end
        end
      end
    end
  end
end
