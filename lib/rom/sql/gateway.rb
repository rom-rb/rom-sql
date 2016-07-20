require 'logger'

require 'rom/gateway'
require 'rom/sql/migration'
require 'rom/sql/commands'

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
      include Options
      include Migration

      class << self
        attr_accessor :instance
      end

      # Return optionally configured logger
      #
      # @return [Object] logger
      #
      # @api public
      attr_reader :logger

      # Returns a list of datasets inferred from table names
      #
      # @return [Array] array with table names
      #
      # @api public
      attr_reader :schema

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
      def initialize(uri, options = {})
        repo_options = self.class.option_definitions.names
        conn_options = options.reject { |k, _| repo_options.include?(k) }

        @connection = connect(uri, conn_options)
        @schema = connection.tables
        add_extensions(Array(options[:extensions])) if options[:extensions]

        super(uri, options.reject { |k, _| conn_options.keys.include?(k) })

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

      # Add extensions to the database connection
      #
      # @api private
      def add_extensions(exts)
        connection.extension(*exts)
      end
    end
  end
end
