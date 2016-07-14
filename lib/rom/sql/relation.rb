require 'rom/sql/header'
require 'rom/sql/types'

require 'rom/sql/schema'

require 'rom/sql/relation/reading'
require 'rom/sql/relation/writing'

require 'rom/plugins/relation/view'
require 'rom/plugins/relation/key_inference'
require 'rom/plugins/relation/sql/base_view'
require 'rom/plugins/relation/sql/auto_combine'
require 'rom/plugins/relation/sql/auto_wrap'

require 'rom/support/deprecations'
require 'rom/support/constants'

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
          schema_dsl SQL::Schema::DSL
          schema_inferrer ROM::SQL::Schema::Inferrer

          dataset do
            table = opts[:from].first

            if db.table_exists?(table)
              pk =
                if klass.schema
                  klass.schema.primary_key.map { |type| type.meta[:name] }
                elsif db.respond_to?(:primary_key)
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

      # @api private
      def self.associations
        schema.associations
      end

      def self.primary_key(value)
        Deprecations.announce(
          :primary_key,
          "#{self}.primary_key is deprecated, use schema definition to configure"\
          " primary key"
        )
        option :primary_key, reader: true, default: value
      end

      option :associations, reader: true, default: -> rel {
        rel.schema? ? rel.schema.associations : EMPTY_HASH
      }

      # @api private
      def initialize(dataset, options = EMPTY_HASH)
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

      # Return primary key column name
      #
      # TODO: add support for composite pks
      #
      # @return [Symbol]
      #
      # @api public
      def primary_key
        @primary_key ||= schema? ? schema.primary_key[0].meta[:name] : :id
      end

      # Return raw column names
      #
      # @return [Array<Symbol>]
      #
      # @api private
      def columns
        dataset.columns
      end

      # @api private
      def schema?
        ! schema.nil?
      end
    end
  end
end
