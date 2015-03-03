require 'logger'

require 'rom/repository'
require 'rom/sql/commands'

module ROM
  module SQL
    class Repository < ROM::Repository
      attr_reader :logger, :schema

      def self.database_file?(scheme)
        scheme.to_s.include?('sqlite')
      end

      # SQL repository interface
      #
      # @overload connect(uri, options)
      #   Connects to database via uri passing options
      #
      #   @param [String,Symbol] uri connection URI
      #   @param [Hash] options connection options
      #
      # @overload connect(connection)
      #   Re-uses connection instance
      #
      #   @param [Sequel::Database] connection instance
      #
      # @example
      #   repository = ROM::SQL::Repository.new('postgres://localhost/rom')
      #
      #   # or re-use connection
      #   DB = Sequel.connect('postgres://localhost/rom')
      #   repository = ROM::SQL::Repository.new(DB)
      #
      # @api public
      def initialize(uri, options = {})
        @connection = connect(uri, options)
        @schema = connection.tables
      end

      def disconnect
        connection.disconnect
      end

      def [](name)
        connection[name]
      end

      def use_logger(logger)
        @logger = logger
        connection.loggers << logger
      end

      def dataset(table)
        connection[table]
      end

      def dataset?(name)
        schema.include?(name)
      end

      def extend_command_class(klass, dataset)
        type = dataset.db.database_type

        if type == :postgres
          ext =
            if klass < Commands::Create
              Commands::Postgres::Create
            elsif klass < Commands::Update
              Commands::Postgres::Update
            end

          klass.send(:include, ext) if ext
        end

        klass
      end

      private

      # Connect to database or re-uses connection instance
      #
      # @return [Database::Sequel] a connection instance
      #
      # @api private
      def connect(uri, *args)
        case uri
        when ::Sequel::Database
          uri
        else
          ::Sequel.connect(uri.to_s, *args)
        end
      end
    end
  end
end
