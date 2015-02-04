require 'rom/sql/commands/create'
require 'rom/sql/commands/update'

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

        class Update < Commands::Update
          def update(tuple)
            relation.dataset.returning(*relation.model.columns).update(tuple)
          end
        end
      end
    end
  end
end
