module ROM
  module SQL
    module Migration
      ::Sequel.extension :migration

      def self.run(connection, path, options = {})
        ::Sequel::Migrator.run(connection, path, options)
      end
    end
  end
end
