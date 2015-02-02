require 'rom/sql/commands/create'

module ROM
  module SQL
    module Commands
      module Postgres
        class Create < Commands::Create
          def insert(tuples)
            tuples.map do |tuple|
              relation.dataset.returning(*tuple.keys).insert(tuple)
            end.flatten
          end
        end
      end
    end
  end
end
