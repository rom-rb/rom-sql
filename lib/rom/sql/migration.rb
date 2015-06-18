require 'rom/sql/migration/migrator'

module ROM
  module SQL
    # Create a database migration for a specific gateway
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
    #   # for a non-default gateway
    #   ROM::SQL.migration(:other) do
    #     # ...
    #   end
    #
    # @api public
    def self.migration(gateway = :default, &block)
      gateways = ROM.boot ? ROM.boot.gateways : ROM.env.gateways
      gateways[gateway].migration(&block)
    end

    # Return first sql gateway for migrations
    #
    # This is used by migration tasks, they only support a single sql gateway
    #
    # @api private
    def self.gateway
      ROM.gateways
        .keys
        .detect { |gateway| gateway.instance_of?(Gateway) }
    end

    module Migration
      Sequel.extension :migration

      def self.included(klass)
        super
        klass.class_eval do
          option :migrator, reader: true, default: proc { |gateway|
            Migrator.new(gateway.connection)
          }
        end
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

      # TODO: this should be removed in favor of migration API in Gateway
      class << self
        attr_writer :path
        attr_accessor :connection

        def path
          @path || Migrator::DEFAULT_PATH
        end

        def run(options = {})
          warn "ROM::SQL::Migration.run is deprecated please ROM::SQL::Gateway#run_migrations (#{caller[0]})"
          ::Sequel::Migrator.run(connection, path, options)
        end

        def create(&block)
          warn "ROM::SQL::Migration.create is deprecated please use ROM::SQL.migration (#{caller[0]})"
          ::Sequel.migration(&block)
        end
      end
    end
  end
end
