# frozen_string_literal: true

require "dry/effects"

module ROM
  module Plugins
    module Relation
      module SQL
        # @api private
        module DefaultViews
          extend Dry::Effects.Reader(:registry)

          # @api private
          def self.apply(target, **)
            define_default_views!(target, registry.schemas.canonical(target))
          end

          # @api private
          def self.define_default_views!(target, schema)
            if schema.primary_key.size > 1
              # @!method by_pk(val1, val2)
              #   Return a relation restricted by its composite primary key
              #
              #   @param [Array] args A list with composite pk values
              #
              #   @return [SQL::Relation]
              #
              #   @api public
              target.class_eval <<-RUBY, __FILE__, __LINE__ + 1
                undef :by_pk if method_defined?(:by_pk)

                def by_pk(#{schema.primary_key.map(&:name).join(", ")})
                  where(#{schema.primary_key.map { |attr| "schema.canonical[:#{attr.name}] => #{attr.name}" }.join(", ")})
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
              target.class_eval <<-RUBY, __FILE__, __LINE__ + 1
                undef :by_pk if method_defined?(:by_pk)

                def by_pk(pk)
                  if primary_key.nil?
                    raise MissingPrimaryKeyError.new(
                      "Missing primary key for :\#{schema.name}"
                    )
                  end
                  where(schema.canonical[schema.canonical.primary_key_name].qualified => pk)
                end
              RUBY
            end
          end

          # @api private
          def self.primary_key_columns(db, table)
            names = db.respond_to?(:primary_key) ? Array(db.primary_key(table)) : [:id]
            names.map { |col| :"#{table}__#{col}" }
          end
        end
      end
    end
  end
end

ROM.plugins do
  adapter(:sql) do
    register :default_views, ROM::Plugins::Relation::SQL::DefaultViews, type: :relation
  end
end
