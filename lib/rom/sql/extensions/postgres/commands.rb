# frozen_string_literal: true

require 'rom/sql/commands/create'
require 'rom/sql/commands/update'

module ROM
  module SQL
    module Postgres
      module Commands
        # @api private
        module Core
          private

          # Common dataset used by create/update commands
          #
          # @return [Sequel::Dataset]
          #
          # @api private
          def returning_dataset
            relation.dataset.returning(*relation.schema.qualified_projection)
          end
        end

        module Create
          include Core

          # Executes insert statement and returns inserted tuples
          #
          # @api private
          def insert(tuples)
            dataset = tuples.flat_map do |tuple|
              returning_dataset.insert(tuple)
            end

            wrap_dataset(dataset)
          end

          # Executes multi_insert statement and returns inserted tuples
          #
          # @api private
          def multi_insert(tuples)
            returning_dataset.multi_insert(tuples)
          end

          # Executes upsert statement (INSERT with ON CONFLICT clause)
          # and returns inserted/updated tuples
          #
          # @api private
          def upsert(tuple, opts = EMPTY_HASH)
            returning_dataset.insert_conflict(opts).insert(tuple)
          end
        end

        module Update
          include Core

          # Executes update statement and returns updated tuples
          #
          # @api private
          def update(tuple)
            wrap_dataset(returning_dataset.update(tuple))
          end
        end

        # Upsert command
        #
        # The command being called attempts to insert a record and
        # if the inserted row would violate a unique constraint
        # updates the conflicting row (or silently does nothing).
        # A very important implementation detail is that the whole operation
        # is serializable, i.e. aware of concurrent transactions, and doesn't raise
        # exceptions and doesn't issue missing updates once used properly.
        #
        # See PG's docs in INSERT statement for details
        # https://www.postgresql.org/docs/current/static/sql-insert.html
        #
        # Normally, the command should be configured via class level settings.
        # By default, that is without any setting provided, the command
        # uses the ON CONFLICT DO NOTHING clause.
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

    Commands::Postgres = Postgres::Commands

    Gateway.subscribe('configuration.commands.class.before_build') do |event|
      klass = event[:command]

      # TODO: remove this conditional in favor of `adapter: :sql` in subscribe
      #       this is here for backward compatibilty with rom-core 4.x
      if klass.adapter == :sql
        dataset = event[:dataset]
        type = dataset.db.database_type

        if type == :postgres
          ext =
            if klass < Commands::Create
              Postgres::Commands::Create
            elsif klass < Commands::Update
              Postgres::Commands::Update
            end

          klass.include(ext) if ext
        end
      end
    end
  end
end
