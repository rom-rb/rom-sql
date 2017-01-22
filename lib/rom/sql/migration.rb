require 'rom/sql/migration/migrator'

module ROM
  module SQL
    # Trap for the migration runner. To create a migration
    # on a specific gateway, use ROM::SQL::Gateway#migration
    #
    # @example
    #   ROM.setup(
    #     default: [:sql, 'sqlite::memory'],
    #     other: [:sql, 'postgres://localhost/test']
    #   )
    #
    #   ROM.finalize
    #
    #   ROM::SQL.migration do
    #     change do
    #       create_table(:users) do
    #         primary_key :id
    #         String :name
    #       end
    #     end
    #   end
    #
    # @api public
    def self.migration(&block)
      ROM::SQL::Gateway.instance.migration(&block)
    end

    module Migration
      Sequel.extension :migration

      # @api public
      attr_reader :migrator

      # @api private
      def initialize(uri, options = EMPTY_HASH)
        @migrator = options.fetch(:migrator) { Migrator.new(connection) }
      end

      # @see ROM::SQL::Migration.pending?
      #
      # @api public
      def pending_migrations?
        migrator.pending?
      end

      # @see ROM::SQL.migration
      #
      # @api public
      def migration(&block)
        migrator.migration(&block)
      end

      # Run migrations for a given gateway
      #
      # @example
      #   ROM.setup(:sql, ['sqlite::memory'])
      #   ROM.finalize
      #   ROM.env.gateways[:default].run_migrations
      #
      #
      # @param [Hash] options The options used by Sequel migrator
      #
      # @api public
      def run_migrations(options = {})
        migrator.run(options)
      end
    end
  end
end
