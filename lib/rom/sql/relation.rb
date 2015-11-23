require 'rom/sql/header'

require 'rom/sql/relation/reading'
require 'rom/sql/relation/writing'

require 'rom/plugins/relation/view'
require 'rom/plugins/relation/key_inference'
require 'rom/plugins/relation/sql/base_view'
require 'rom/plugins/relation/sql/auto_combine'
require 'rom/plugins/relation/sql/auto_wrap'

module ROM
  module SQL
    # Sequel-specific relation extensions
    #
    class Relation < ROM::Relation
      adapter :sql

      use :key_inference
      use :view
      use :base_view
      use :auto_combine
      use :auto_wrap

      include Writing
      include Reading

      # @attr_reader [Header] header Internal lazy-initialized header
      attr_reader :header

      # Name of the table used in FROM clause
      #
      # @attr_reader [Symbol] table
      attr_reader :table

      def self.primary_key(value)
        option :primary_key, reader: true, default: value
      end

      primary_key :id

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
