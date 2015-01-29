module ROM
  module SQL
    class Migration
      ::Sequel.extension :migration

      DEFAULT_PATH = 'db/migrate'

      attr_accessor :path, :connection

      def path
        @path || DEFAULT_PATH
      end

      def run(options = {})
        ::Sequel::Migrator.run(connection, path, options)
      end

      def self.create(&block)
        ::Sequel.migration(&block)
      end
    end
  end
end
