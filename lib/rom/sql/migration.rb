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
      ROM.env.repositories[repository].migration(&block)
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

      def migration(&block)
        migrator.migration(&block)
      end

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
          ::Sequel::Migrator.run(connection, path, options)
        end

        def create(&block)
          ::Sequel.migration(&block)
        end
      end
    end
  end
end
