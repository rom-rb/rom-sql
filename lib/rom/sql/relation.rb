require 'rom/sql/header'

require 'rom/sql/schema'
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
      include SQL

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

      # Set default dataset for a relation sub-class
      #
      # @api private
      def self.inherited(klass)
        super

        klass.class_eval do
          dataset do
            table = opts[:from].first

            if db.table_exists?(table)
              # quick fix for dbs w/o primary_key inference
              #
              # TODO: add a way of setting a pk explicitly on a relation
              pk =
                if db.respond_to?(:primary_key)
                  Array(db.primary_key(table))
                else
                  [:id]
                end.map { |name| :"#{table}__#{name}" }

                select(*columns).order(*pk)
            else
              self
            end
          end
        end
      end

      def self.primary_key(value)
        option :primary_key, reader: true, default: value
      end

      primary_key :id

      def self.schema(&block)
        if defined?(@schema)
          @schema
        elsif block
          @schema = Schema::DSL.new(&block).call
        end
      end

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
