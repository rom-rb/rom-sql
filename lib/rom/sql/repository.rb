require 'logger'

require 'rom/repository'
require 'rom/sql/commands'

module ROM
  module SQL
    class Repository < ROM::Repository
      attr_reader :logger

      def self.database_file?(scheme)
        scheme.to_s.include?('sqlite')
      end

      def initialize(uri, options={})
        @connection = ::Sequel.connect(uri.to_s, options)
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

      def schema
        connection.tables
      end

      def dataset(table)
        connection[table]
      end

      def dataset?(name)
        schema.include?(name)
      end

      def extend_relation_class(klass)
        klass.send(:include, RelationInclusion)
      end

      def extend_relation_instance(relation)
        model = relation.model
        model.set_dataset(relation.dataset)
        model.dataset.naked!
      end

      def command_namespace
        SQL::Commands
      end
    end
  end
end
