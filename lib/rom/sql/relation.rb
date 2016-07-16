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
      EMPTY_ASSOCIATION_SET = AssociationSet.new({}).freeze

      include SQL

      adapter :sql

      use :key_inference
      use :view
      use :base_view
      use :auto_combine
      use :auto_wrap

      include Writing
      include Reading

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

      # Set primary key
      #
      # @deprecated
      #
      # @api public
      def self.primary_key(value)
        Deprecations.announce(
          :primary_key, "use schema definition to configure primary key"
        )
        option :primary_key, reader: true, default: value
      end

      option :associations, reader: true, default: -> rel {
        rel.schema? ? rel.schema.associations : EMPTY_ASSOCIATION_SET
      }

      # Return table name from relation's sql statement
      #
      # This value is used by `header` for prefixing column names
      #
      # @return [Symbol]
      #
      # @api private
      def table
        @table ||= dataset.opts[:from].first
      end

      # Return a header for this relation
      #
      # @return [Header]
      #
      # @api private
      def header
        @header ||= Header.new(selected_columns, table)
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
        @columns ||= dataset.columns
      end

      # @api private
      def schema?
        ! schema.nil?
      end

      protected

      # Return a list of columns from *the sql select* statement or default to
      # dataset columns
      #
      # This is used to construct relation's header
      #
      # @return [Array<Symbol>]
      #
      # @api private
      def selected_columns
        @selected_columns ||= dataset.opts.fetch(:select, columns)
      end
    end
  end
end
