require 'rom/sql/migration/migrator'

module ROM
  module SQL
    # Trap for the migration runner. To create a migration
    # on a specific gateway, use ROM::SQL::Gateway#migration
    #
    # @example
    #   rom = ROM.container(
    #     default: [:sql, 'sqlite::memory'],
    #     other: [:sql, 'postgres://localhost/test']
    #   )
    #
    #   # default gateway migrations
    #   ROM::SQL.migration do
    #     change do
    #       create_table(:users) do
    #         primary_key :id
    #         String :name
    #       end
    #     end
    #   end
    #
    #   # other gateway migrations
    #   rom.gateways[:other].migration do
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

      # @!attribute [r] migrator
      #   @return [Migrator] Migrator instance
      attr_reader :migrator

      # @api private
      def initialize(uri, options = EMPTY_HASH)
        @migrator = options.fetch(:migrator) { Migrator.new(connection) }
      end

      # Check if there are any pending migrations
      #
      # @see ROM::SQL::Migration.pending?
      #
      # @api public
      def pending_migrations?
        migrator.pending?
      end

      # Migration DSL
      #
      # @see ROM::SQL.migration
      #
      # @api public
      def migration(&block)
        migrator.migration(&block)
      end

      # Run migrations
      #
      # @example
      #   rom = ROM.container(:sql, ['sqlite::memory'])
      #   rom.gateways[:default].run_migrations
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
