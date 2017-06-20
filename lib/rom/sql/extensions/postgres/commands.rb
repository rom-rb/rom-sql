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
            dataset = tuples.map do |tuple|
              relation.dataset.returning.insert(tuple)
            end.flatten(1)

            wrap_dataset(dataset)
          end

          # Executes multi_insert statement and returns inserted tuples
          #
          # @api private
          def multi_insert(tuples)
            relation.dataset.returning.multi_insert(tuples)
          end

          # Executes upsert statement (INSERT with ON CONFLICT clause)
          # and returns inserted/updated tuples
          #
          # @api private
          def upsert(tuple, opts = EMPTY_HASH)
            relation.dataset.returning.insert_conflict(opts).insert(tuple)
          end
        end

        module Update
          # Executes update statement and returns updated tuples
          #
          # @api private
          def update(tuple)
            dataset = relation.dataset.returning.update(tuple)
            wrap_dataset(dataset)
          end
        end

        # Upsert command
        #
        # Uses a feature of PostgreSQL 9.5 commonly called an "upsert".
        # The command been called attempts to perform an insert and
        # can make an update (or silently do nothing) in case of
        # the insertion was unsuccessful due to a violation of a unique
        # constraint.
        # Very important implementation detail is that the whole operation
        # is atomic, i.e. aware of concurrent transactions, and doesn't raise
        # exceptions if used properly.
        #
        # See PG's docs in INSERT statement for details
        # https://www.postgresql.org/docs/current/static/sql-insert.html
        #
        # Normally, the command should configured via class level settings.
        # By default, that is without any settings provided, the command
        # uses ON CONFLICT DO NOTHING clause.
        #
        # This implementation uses Sequel's API underneath, the docs are available at
        # http://sequel.jeremyevans.net/rdoc-adapters/classes/Sequel/Postgres/DatasetMethods.html#method-i-insert_conflict
        #
        # @api public
        class Upsert < SQL::Commands::Create
          adapter :sql

          defines :constraint, :conflict_target, :update_statement, :update_where

          # @!attribute [r] constraint
          #  @return [Symbol] the name of the constraint expected to be violated
          option :constraint, default: -> { self.class.constraint }

          # @!attribute [r] conflict_target
          #  @return [Object] the column or expression to handle a violation on
          option :conflict_target, default: -> { self.class.conflict_target }

          # @!attribute [r] update_statement
          #  @return [Object] the update statement which will be executed in case of a violation
          option :update_statement, default: -> { self.class.update_statement }

          # @!attribute [r] update_where
          #  @return [Object] the WHERE clause to be added to the update
          option :update_where, default: -> { self.class.update_where }

          # Tries to insert provided tuples and do an update (or nothing)
          # when the inserted record violates a unique constraint and hence
          # cannot be appended to the table
          #
          # @return [Array<Hash>]
          #
          # @api public
          def execute(tuples)
            inserted_tuples = with_input_tuples(tuples) do |tuple|
              upsert(input[tuple], upsert_options)
            end

            inserted_tuples.flatten(1)
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
