require 'rom/sql/header'

require 'rom/sql/relation/class_methods'
require 'rom/sql/relation/reading'
require 'rom/sql/relation/writing'
require 'rom/sql/relation/inspection'
require 'rom/sql/relation/associations'

module ROM
  module SQL
    # Sequel-specific relation extensions
    #
    class Relation < ROM::Relation
      adapter :sql

      extend ClassMethods

      include Inspection
      include Associations
      include Writing
      include Reading

      # @attr_reader [Header] header Internal lazy-initialized header
      attr_reader :header

      # Name of the table used in FROM clause
      #
      # @attr_reader [Symbol] table
      attr_reader :table

      # @api private
      def initialize(dataset, registry = {})
        super
        @table = dataset.opts[:from].first
      end

      # Return a header for this relation
      #
      # @return [Header]
      #
      # @api private
      def header
        @header ||= Header.new(dataset.opts[:select] || dataset.columns, table)
      end

      # Return raw column names
      #
      # @return [Array<Symbol>]
      #
      # @api private
      def columns
        dataset.columns
      end
    end
  end
end
