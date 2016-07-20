module ROM
  module SQL
    module Commands
      module Postgres
        class Upsert < SQL::Commands::Create
          adapter :sql

          # @api private
          def execute(tuples)
            inserted_tuples = with_input_tuples(tuples) do |tuple|
              upsert.call(input[tuple])
            end

            inserted_tuples.flatten
          end
        end
      end
    end
  end
end
