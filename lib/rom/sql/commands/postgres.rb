module ROM
  module SQL
    module Commands
      module Postgres
        class Upsert < SQL::Commands::Create
          adapter :sql

          defines :constraint, :conflict_target, :update_statement, :update_where

          option :constraint, reader: true, default: -> c { c.class.constraint }
          option :conflict_target, reader: true, default: -> c { c.class.conflict_target }
          option :update_statement, reader: true, default: -> c { c.class.update_statement }
          option :update_where, reader: true, default: -> c { c.class.update_where }

          # @api private
          def execute(tuples)
            inserted_tuples = with_input_tuples(tuples) do |tuple|
              upsert(input[tuple], upsert_options)
            end

            inserted_tuples.flatten
          end

          # @api private
          def upsert_options
            @upsert_options ||= {
              constraint: constraint,
              target: conflict_target,
              update_where: update_where,
              update: update_statement
            }
          end
        end
      end
    end
  end
end
