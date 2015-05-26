require 'rom/sql/migration/migrator'

module ROM
  module SQL
    # Create a database migration for a specific repository
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
    #   # for a non-default repository
    #   ROM::SQL.migration(:other) do
    #     # ...
    #   end
    #
    # @api public
    def self.migration(repository = :default, &block)
      ROM.env.gateways[repository].migration(&block)
    end

    module Migration
      Sequel.extension :migration

      def self.included(klass)
        super
        klass.class_eval do
          option :migrator, reader: true, default: proc { |repository|
            Migrator.new(repository.connection)
          }
        end
      end

      # @see ROM::SQL.migration
      #
      # @api public
      def migration(&block)
        migrator.migration(&block)
      end

      # Run migrations for a given repository
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

      # TODO: this should be removed in favor of migration API in Repository
      class << self
        attr_writer :path
        attr_accessor :connection

        def path
          @path || Migrator::DEFAULT_PATH
        end

        def run(options = {})
          warn "ROM::SQL::Migration.run is deprecated please ROM::SQL::Repository#run_migrations (#{caller[0]})"
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
