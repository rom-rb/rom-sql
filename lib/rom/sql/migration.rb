# frozen_string_literal: true

require 'rom/sql/migration/migrator'
require 'rom/sql/migration/schema_diff'

module ROM
  module SQL
    class << self
      # Trap for the migration runner. By default migrations are
      # bound to the gateway you're using to run them.
      # You also can explicitly pass a configuration object and a gateway name
      # but this normally won't be not required.
      #
      # @example
      #   # Ordinary migration
      #   ROM::SQL.migration do
      #     change do
      #       create_table(:users) do
      #         primary_key :id
      #         String :name
      #       end
      #     end
      #   end
      #
      # @example
      #   # Providing a config
      #   rom = ROM::Configuration.new(
      #     default: [:sql, 'sqlite::memory'],
      #     other: [:sql, 'postgres://localhost/test']
      #   )
      #
      #   # default gateway migrations
      #   ROM::SQL.migration(rom) do
      #     change do
      #       create_table(:users) do
      #         primary_key :id
      #         String :name
      #       end
      #     end
      #   end
      #
      #   # other gateway migrations
      #   ROM::SQL.migration(rom, :other) do
      #     change do
      #       create_table(:users) do
      #         primary_key :id
      #         String :name
      #       end
      #     end
      #   end
      #
      # @overload migration(container, gateway)
      #   @param [ROM::Container] container The container instance used for accessing gateways
      #   @param [Symbol] gateway The gateway name, :default by default
      #
      # @api public
      def migration(*args, &block)
        if args.any?
          container, gateway, * = args
          with_gateway(container.gateways[gateway || :default]) { migration(&block) }
        else
          current_gateway.migration(&block)
        end
      end

      # @api private
      attr_accessor :current_gateway

      # This method is used on loading migrations.
      # Temporally sets the global "current_gateway", you shouln't access it.
      #
      # @api private
      def with_gateway(gateway)
        current = @current_gateway
        @current_gateway = gateway

        yield
      ensure
        @current_gateway = current
      end
    end

    @current_gateway = nil

    module Migration
      # FIXME: remove in 2.0
      #
      # @api private
      def self.included(base)
        super

        base.singleton_class.send(:attr_accessor, :instance)
      end

      Sequel.extension :migration

      # @!attribute [r] migrator
      #   @return [Migrator] Migrator instance
      attr_reader :migrator

      # @api private
      def initialize(_uri, options = EMPTY_HASH)
        @migrator = create_migrator(options[:migrator])

        self.class.instance ||= self
      end

      # Check if there are any pending migrations
      #
      # @see ROM::SQL::Migration.pending?
      #
      # @api public
      def pending_migrations?
        ROM::SQL.with_gateway(self) {
          migrator.pending?
        }
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
        ROM::SQL.with_gateway(self) {
          migrator.run(options)
        }
      end

      # @api public
      def auto_migrate!(conf, options = EMPTY_HASH)
        schemas = conf.relation_classes(self).map do |klass|
          klass.schema_proc.call.finalize_attributes!(gateway: self)
        end

        migrator.auto_migrate!(self, schemas, options)
      end

      private

      # Create a `Migrator`. If `migrator_option` is a `Hash`, use it as options to `Migrator.new`.
      #
      # @api private
      def create_migrator(migrator_option)
        return Migrator.new(connection) unless migrator_option

        if migrator_option.is_a?(Hash)
          Migrator.new(connection, **migrator_option)
        else
          migrator_option
        end
      end
    end
  end
end
