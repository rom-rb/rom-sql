module ROM
  module SQL
    module Migration
      class Migrator
        include Options

        DEFAULT_PATH = 'db/migrate'.freeze

        option :path, reader: true, default: DEFAULT_PATH

        attr_reader :connection

        def initialize(connection, options = {})
          super
          @connection = connection
        end

        def run(options = {})
          Sequel::Migrator.run(connection, path.to_s, options)
        end

        def migration(&block)
          Sequel.migration(&block)
        end
      end
    end
  end
end
