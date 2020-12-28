# frozen_string_literal: true

require 'logger'
require 'sequel/core'

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
    # @api public
    class Gateway < ROM::Gateway
      include Dry::Core::Constants
      include Migration

      adapter :sql

      CONNECTION_EXTENSIONS = {
        postgres: %i[pg_array pg_json pg_enum]
      }.freeze

      # @!attribute [r] logger
      #   @return [Object] configured gateway logger
      attr_reader :logger

      # @!attribute [r] options
      #   @return [Hash] Options used for connection
      attr_reader :options

      # Initialize an SQL gateway
      #
      # Gateways are typically initialized via ROM::Configuration object, gateway constructor
      # arguments such as URI and options are passed directly to this constructor
      #
      # @overload initialize(uri)
      #   Connects to a database via URI
      #
      #   @example
      #     ROM.container(:sql, 'postgres://localhost/db_name')
      #
      #   @param [String,Symbol] uri connection URI
      #
      # @overload initialize(uri, options)
      #   Connects to a database via URI and options
      #
      #   @example
      #     ROM.container(:sql, 'postgres://localhost/db_name', extensions: %w[pg_enum])
      #
      #   @param [String,Symbol] uri connection URI
      #
      #   @param [Hash] options connection options
      #
      #   @option options [Array<Symbol>] :extensions
      #     A list of connection extensions supported by Sequel
      #
      #   @option options [String] :user Database username
      #
      #   @option options [String] :password Database password
      #
      # @overload initialize(connection)
      #   Creates a gateway from an existing database connection. This
      #   works with Sequel connections exclusively.
      #
      #   @example
      #     ROM.container(:sql, Sequel.connect(:sqlite))
      #
      #   @param [Sequel::Database] connection a connection instance
      #
      # @return [SQL::Gateway]
      #
      # @see https://github.com/jeremyevans/sequel/blob/master/doc/opening_databases.rdoc Sequel connection docs
      #
      # @api public
      def initialize(uri, options = EMPTY_HASH)
        @connection = connect(uri, options)
        load_extensions(Array(options[:extensions]))
        Notifications.trigger("configuration.gateway.connected", connection: @connection)

        @options = options

        super
      end

      # Disconnect from the gateway's database
      #
      # @api public
      def disconnect
        connection.disconnect
      end

      # Return dataset with the given name
      #
      # This returns a raw Sequel database
      #
      # @param [String, Symbol] name The dataset name
      #
      # @return [Dataset]
      #
      # @api public
      def [](name)
        connection[name]
      end

      # Setup a logger
      #
      # @example set a logger during configuration process
      #   rom = ROM.container(:sql, 'sqlite::memory') do |config|
      #     config.gateways[:default].use_logger(Logger.new($stdout))
      #   end
      #
      # @example set logger after gateway has been established
      #   rom = ROM.container(:sql, 'sqlite::memory')
      #   rom.gateways[:default].use_logger(Logger.new($stdout))
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

      # Check if a dataset exists
      #
      # @param [String] name dataset name
      #
      # @api public
      def dataset?(name)
        schema.include?(name)
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

      # Underlying database type
      #
      # @return [Symbol]
      #
      # @api public
      def database_type
        @database_type ||= connection.database_type.to_sym
      end

      # Call a SQL function
      #
      # @example
      #   gateway.(:upper, 'John Doe') # => "JOHN DOE"
      #
      # @param [Symbol] function Function name
      # @param [Array<Object>] args Function arguments
      #
      # @return [Object]
      #
      # @api public
      def call(function, *args)
        connection[Sequel.function(function, *args)].first.values.first
      end

      # Execute a statement
      #
      # @param [String] statement
      #
      # @api public
      def run(statement)
        connection.run(statement)
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
        when Hash
          ::Sequel.connect(uri, *args)
        else
          ::Sequel.connect(uri.to_s, *args)
        end
      end

      # Load database-specific extensions
      #
      # @api private
      def load_extensions(exts)
        if ROM::SQL.available_extension?(database_type)
          ROM::SQL.load_extensions(database_type)
        end

        extensions = (CONNECTION_EXTENSIONS.fetch(database_type, EMPTY_ARRAY) + exts).uniq
        connection.extension(*extensions)

        # this will be default in Sequel 5.0.0 and since we don't rely
        # on dataset mutation it is safe to enable it already
        connection.extension(:freeze_datasets) unless RUBY_ENGINE == 'rbx'

        # for ROM::SQL::Relation#nullify
        connection.extension(:null_dataset)
      end

      # @api private
      def transaction_runner(_)
        ROM::SQL::Transaction.new(connection)
      end
    end
  end

  Configuration.register_event("configuration.gateway.connected")
end
