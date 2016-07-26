require 'rom/sql/commands/create'
require 'rom/sql/commands/update'

module ROM
  module SQL
    module Commands
      module Postgres
        module Create
          # Executes insert statement and returns inserted tuples
          #
          # @api private
          def insert(tuples)
            tuples.map do |tuple|
              relation.dataset.returning(*relation.columns).insert(tuple)
            end.flatten
          end

          # Executes multi_insert statement and returns inserted tuples
          #
          # @api private
          def multi_insert(tuples)
            relation.dataset.returning(*relation.columns).multi_insert(tuples)
          end

          # Executes upsert statement (INSERT with ON CONFLICT clause)
          # and returns inserted/updated tuples
          #
          # @api private
          def upsert(tuple, opts = EMPTY_HASH)
            relation.dataset.returning(*relation.columns).insert_conflict(opts).insert(tuple)
          end
        end

        module Update
          # Executes update statement and returns updated tuples
          #
          # @api private
          def update(tuple)
            relation.dataset.returning(*relation.columns).update(tuple)
          end
        end
      end
    end
  end
end
