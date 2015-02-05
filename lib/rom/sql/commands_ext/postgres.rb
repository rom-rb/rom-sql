require 'rom/sql/commands/create'
require 'rom/sql/commands/update'

module ROM
  module SQL
    module Commands
      module Postgres
        class Create < Commands::Create
          def insert(tuples)
            tuples.map do |tuple|
              relation.dataset.returning(*relation.columns).insert(tuple)
            end.flatten
          end
        end

        class Update < Commands::Update
          def update(tuple)
            relation.dataset.returning(*relation.columns).update(tuple)
          end
        end
      end
    end
  end
end
