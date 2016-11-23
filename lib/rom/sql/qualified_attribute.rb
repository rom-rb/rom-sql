require 'dry/core/cache'

module ROM
  module SQL
    # Used as a pair table name + field name.
    # Similar to Sequel::SQL::QualifiedIdentifier but we don't want
    # Sequel types to leak into ROM
    #
    # @api private
    class QualifiedAttribute
      include Dry::Equalizer(:dataset, :attribute)

      extend Dry::Core::Cache

      # Dataset (table) name
      #
      # @api private
      attr_reader :dataset

      # Attribute (field, column) name
      #
      # @api private
      attr_reader :attribute

      # @api private
      def self.[](*args)
        fetch_or_store(args) { new(*args) }
      end

      # @api private
      def initialize(dataset, attribute)
        @dataset = dataset
        @attribute = attribute
      end

      # Used by Sequel for building SQL statements
      #
      # @api private
      def sql_literal_append(ds, sql)
        ds.qualified_identifier_sql_append(sql, dataset, attribute)
      end

      # Convinient interface for attribute names
      #
      # @return [Symbol]
      #
      # @api private
      def to_sym
        attribute
      end
    end
  end
end
