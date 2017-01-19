require 'rom/sql/types'
require 'rom/sql/schema'

require 'rom/sql/relation/reading'
require 'rom/sql/relation/writing'
require 'rom/sql/relation/sequel_api'

require 'rom/plugins/relation/key_inference'
require 'rom/plugins/relation/sql/auto_combine'
require 'rom/plugins/relation/sql/auto_wrap'

module ROM
  module SQL
    # Sequel-specific relation extensions
    #
    # @api public
    class Relation < ROM::Relation
      include SQL

      adapter :sql

      use :key_inference
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
              ROM::Schema::DEFAULT_INFERRER.()
            end
          end

          dataset do
            # TODO: feels strange to do it here - we need a new hook for this during finalization
            klass.define_default_views!
            schema = klass.schema

            table = opts[:from].first

            if db.table_exists?(table)
              if schema
                select(*schema.map(&:to_sym)).order(*schema.project(*schema.primary_key_names).qualified.map(&:to_sym))
              else
                select(*columns).order(*klass.primary_key_columns(db, table))
              end
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
        view(:by_pk, schema.map(&:name)) do |pk|
          where(primary_key => pk)
        end
      end

      # @api private
      def self.associations
        schema.associations
      end

      # @api private
      def self.primary_key_columns(db, table)
        names = db.respond_to?(:primary_key) ? Array(db.primary_key(table)) : [:id]
        names.map { |col| :"#{table}__#{col}" }
      end

      option :primary_key, reader: true, default: -> rel { rel.schema.primary_key_name }

      # Return raw column names
      #
      # @return [Array<Symbol>]
      #
      # @api private
      def columns
        @columns ||= dataset.columns
      end
    end
  end
end
