require 'logger'

require 'dry/core/constants'

require 'rom/types'
require 'rom/gateway'
require 'rom/sql/migration'
require 'rom/sql/commands'
require 'rom/sql/transaction'

module ROM
  module SQL
    # SQL gateway
    #
    # @example
    #   db = Sequel.connect(:sqlite)
    #   gateway = ROM::SQL::Gateway.new(db)
    #
    #   users = gateway.dataset(:users)
    #
    # @api public
    class Gateway < ROM::Gateway
      include Dry::Core::Constants
      include Migration

      class << self
        attr_accessor :instance
      end

      CONNECTION_EXTENSIONS = {
        postgres: %i(pg_array pg_json pg_enum)
      }.freeze

      # Return optionally configured logger
      #
      # @return [Object] logger
      #
      # @api public
      attr_reader :logger

      # @api private
      attr_reader :options

      # SQL gateway interface
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
      #   @param [Sequel::Database] connection a connection instance
      #
      # @example
      #   gateway = ROM::SQL::Gateway.new('postgres://localhost/rom')
      #
      #   # or reuse connection
      #   DB = Sequel.connect('postgres://localhost/rom')
      #   gateway = ROM::SQL::Gateway.new(DB)
      #
      # @api public
      def initialize(uri, options = EMPTY_HASH)
        @connection = connect(uri, options)
        load_extensions(Array(options[:extensions]))

        @options = options

        super

        self.class.instance = self
      end

      # Disconnect from database
      #
      # @api public
      def disconnect
        connection.disconnect
      end

      # Return dataset with the given name
      #
      # @param [String] name dataset name
      #
      # @return [Dataset]
      #
      # @api public
      def [](name)
        connection[name]
      end

      # Setup a logger
      #
      # @param [Object] logger
      #
      # @see Sequel::Database#loggers
      #
      # @api public
      def use_logger(logger)
        @logger = logger
        connection.loggers << logger
      end

      # Return dataset with the given name
      #
      # @param [String] name a dataset name
      #
      # @return [Dataset]
      #
      # @api public
      def dataset(name)
        connection[name]
      end

      # Check if dataset exists
      #
      # @param [String] name dataset name
      #
      # @api public
      def dataset?(name)
        schema.include?(name)
      end

      # Extend database-specific behavior
      #
      # @param [Class] klass command class
      # @param [Object] dataset a dataset that will be used
      #
      # Note: Currently, only postgres is supported.
      #
      # @api public
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

      # Create a table using the configured connection
      #
      # @api public
      def create_table(*args, &block)
        connection.create_table(*args, &block)
      end

      # Drops a table
      #
      # @api public
      def drop_table(*args, &block)
        connection.drop_table(*args, &block)
      end

      # Returns a list of datasets inferred from table names
      #
      # @return [Array] array with table names
      #
      # @api public
      def schema
        @schema ||= connection.tables
      end

      private

      # Connect to database or reuse established connection instance
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

      # Load database-specific extensions
      #
      # @api private
      def load_extensions(exts)
        db_type = connection.database_type.to_sym

        if ROM::SQL.available_extension?(db_type)
          ROM::SQL.load_extensions(db_type)
        end

        extensions = (CONNECTION_EXTENSIONS.fetch(db_type, EMPTY_ARRAY) + exts).uniq
        connection.extension(*extensions)

        # this will be default in Sequel 5.0.0 and since we don't rely
        # on dataset mutation it is safe to enable it already
        connection.extension(:freeze_datasets)
      end

      # @api private
      def transaction_runner(_)
        ROM::SQL::Transaction.new(connection)
      end
    end
  end
end
