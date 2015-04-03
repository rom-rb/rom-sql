require 'rom/sql/migration/migrator'

module ROM
  module SQL
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
