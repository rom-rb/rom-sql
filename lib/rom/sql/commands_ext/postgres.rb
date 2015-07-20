require 'rom/sql/commands/create'
require 'rom/sql/commands/update'

module ROM
  module SQL
    module Commands
      module Postgres
        module Create
          def insert(tuples)
            tuples.map do |tuple|
              relation.dataset.returning(*relation.columns).insert(tuple)
            end.flatten
          end

          def multi_insert(tuples)
            relation.dataset.returning(*relation.columns).multi_insert(tuples)
          end
        end

        module Update
          def update(tuple)
            relation.dataset.returning(*relation.columns).update(tuple)
          end
        end
      end
    end
  end
end
