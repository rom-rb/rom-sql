require 'rom/sql/types'
require 'rom/sql/schema'
require 'rom/sql/attribute'
require 'rom/sql/wrap'

require 'rom/sql/relation/reading'
require 'rom/sql/relation/writing'
require 'rom/sql/relation/sequel_api'

module ROM
  module SQL
    # Sequel-specific relation extensions
    #
    # @api public
    class Relation < ROM::Relation
      adapter :sql

      include SQL
      include Writing
      include Reading

      extend Notifications::Listener

      schema_class SQL::Schema
      schema_attr_class SQL::Attribute
      schema_inferrer -> (name, gateway) do
        inferrer_for_db = ROM::SQL::Schema::Inferrer.get(gateway.connection.database_type.to_sym)
        begin
          inferrer_for_db.new.call(name, gateway)
        rescue Sequel::Error => e
          inferrer_for_db.on_error(name, e)
          ROM::Schema::DEFAULT_INFERRER.()
        end
      end
      wrap_class SQL::Wrap

      subscribe('configuration.relations.schema.set', adapter: :sql) do |event|
        schema = event[:schema]
        relation = event[:relation]

        relation.dataset do
          table = opts[:from].first

          if db.table_exists?(table)
            select(*schema).order(*schema.project(*schema.primary_key_names).qualified)
          else
            self
          end
        end
      end

      subscribe('configuration.relations.dataset.allocated', adapter: :sql) do |event|
        event[:relation].define_default_views!
      end

      # @api private
      def self.define_default_views!
        if schema.primary_key.size > 1
          # @!method by_pk(val1, val2)
          #   Return a relation restricted by its composite primary key
          #
          #   @param [Array] args A list with composite pk values
          #
          #   @return [SQL::Relation]
          #
          #   @api public
          class_eval <<-RUBY, __FILE__, __LINE__ + 1
            def by_pk(#{schema.primary_key.map(&:name).join(', ')})
              where(#{schema.primary_key.map { |attr| "self.class.schema[:#{attr.name}] => #{attr.name}" }.join(', ')})
            end
          RUBY
        else
          # @!method by_pk(pk)
          #   Return a relation restricted by its primary key
          #
          #   @param [Object] pk The primary key value
          #
          #   @return [SQL::Relation]
          #
          #   @api public
          class_eval <<-RUBY, __FILE__, __LINE__ + 1
            def by_pk(pk)
              if primary_key.nil?
                raise MissingPrimaryKeyError.new(
                  "Missing primary key for :\#{schema.name}"
                )
              end
              where(self.class.schema[self.class.schema.primary_key_name].qualified => pk)
            end
          RUBY
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

      option :primary_key, default: -> { schema.primary_key_name }

      # Return relation that will load associated tuples of this relation
      #
      # This method is useful for defining custom relation views for relation
      # composition when you want to enhance default association query
      #
      # @example
      #   assoc(:tasks).where(tasks[:title] => "Task One")
      #
      # @param [Symbol] name The association name
      #
      # @return [Relation]
      #
      # @api public
      def assoc(name)
        associations[name].()
      end

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
