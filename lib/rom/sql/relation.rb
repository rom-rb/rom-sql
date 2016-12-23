require 'rom/sql/header'
require 'rom/sql/types'

require 'rom/sql/schema'

require 'rom/sql/relation/reading'
require 'rom/sql/relation/writing'

require 'rom/plugins/relation/view'
require 'rom/plugins/relation/key_inference'
require 'rom/plugins/relation/sql/auto_combine'
require 'rom/plugins/relation/sql/auto_wrap'

require 'dry/core/deprecations'

module ROM
  module SQL
    # Sequel-specific relation extensions
    #
    # @api public
    class Relation < ROM::Relation
      include SQL

      adapter :sql

      use :key_inference
      use :view
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

          schema_inferrer -> (name, gateway) do
            inferrer_for_db = ROM::SQL::Schema::Inferrer.get(gateway.connection.database_type.to_sym)
            begin
              inferrer_for_db.new.call(name, gateway)
            rescue Sequel::Error => e
              warn "Error when inferring #{dataset.inspect} relation: #{e.message}"
              {}
            end
          end

          dataset do
            # TODO: feels strange to do it here - we need a new hook for this during finalization
            klass.define_default_views!

            table = opts[:from].first

            if db.table_exists?(table)
              pk_header = klass.primary_key_header(db, table)
              col_names = klass.schema ? klass.schema.attributes.keys : columns
              select(*col_names).order(*pk_header)
            else
              self
            end
          end
        end
      end

      # @api private
      def self.define_default_views!
        # @!method by_pk(pk)
        #   Return a relation restricted by its primary key
        #   @param [Object] pk The primary key value
        #   @return [SQL::Relation]
        #   @api public
        view(:by_pk, attributes[:base]) do |pk|
          where(primary_key => pk)
        end
      end

      # @api private
      def self.associations
        schema.associations
      end

      # @api private
      def self.primary_key_header(db, table)
        names =
          if schema
            schema.primary_key_names
          elsif db.respond_to?(:primary_key)
            Array(db.primary_key(table))
          else
            [:id]
          end
        names.map { |col| :"#{table}__#{col}" }
      end

      # Set primary key
      #
      # @deprecated
      #
      # @api public
      def self.primary_key(value)
        Dry::Core::Deprecations.announce(
          :primary_key,
          "use schema definition to configure primary key",
          tag: :rom
        )
        option :primary_key, reader: true, default: value
      end

      option :primary_key, reader: true, default: -> rel {
        rel.schema? ? rel.schema.primary_key_name : :id
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

      # Return raw column names
      #
      # @return [Array<Symbol>]
      #
      # @api private
      def columns
        @columns ||= dataset.columns
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
