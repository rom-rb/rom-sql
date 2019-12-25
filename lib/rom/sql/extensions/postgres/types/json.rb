# frozen_string_literal: true

require 'sequel/core'
require 'singleton'

Sequel.extension(:pg_json, :pg_json_ops)

module ROM
  module SQL
    module Postgres
      module Types
        JSONRead = (SQL::Types::Array | SQL::Types::Hash).constructor do |value|
          if value.respond_to?(:to_hash)
            value.to_hash
          elsif value.respond_to?(:to_ary)
            value.to_ary
          else
            value
          end
        end

        class JSONNullType
          include ::Singleton

          def to_s
            'null'
          end

          def inspect
            'null'
          end
        end

        JSONNull = JSONNullType.instance.freeze

        if ::Sequel.respond_to?(:pg_json_wrap)
          primitive_json_types = [
            SQL::Types::Array,
            SQL::Types::Hash,
            SQL::Types::Integer,
            SQL::Types::Float,
            SQL::Types::String,
            SQL::Types::True,
            SQL::Types::False
          ]

          JSON = Type('json') do
            casts = ::Hash.new(-> v { ::Sequel.pg_json(v) })
            json_null = ::Sequel.pg_json_wrap(nil)
            casts[JSONNullType] = -> _ { json_null }
            casts[::NilClass] = -> _ { json_null }
            primitive_json_types.each do |type|
              casts[type.primitive] = -> v { ::Sequel.pg_json_wrap(v) }
            end
            casts.freeze

            [*primitive_json_types, SQL::Types.Constant(JSONNull)]
              .reduce(:|)
              .constructor { |value| casts[value.class].(value) }
              .meta(read: JSONRead)
          end

          JSONB = Type('jsonb') do
            casts = ::Hash.new(-> v { ::Sequel.pg_jsonb(v) })
            jsonb_null = ::Sequel.pg_jsonb_wrap(nil)
            casts[JSONNullType] = -> _ { jsonb_null }
            casts[::NilClass] = -> _ { jsonb_null }
            primitive_json_types.each do |type|
              casts[type.primitive] = -> v { ::Sequel.pg_jsonb_wrap(v) }
            end
            casts.freeze

            [*primitive_json_types, SQL::Types.Constant(JSONNull)]
              .reduce(:|)
              .constructor { |value| casts[value.class].(value) }
              .meta(read: JSONRead)
          end
        else
          JSON = Type('json') do
            (SQL::Types::Array | SQL::Types::Hash).constructor(Sequel.method(:pg_json)).meta(read: JSONRead)
          end

          JSONB = Type('jsonb') do
            (SQL::Types::Array | SQL::Types::Hash).constructor(Sequel.method(:pg_jsonb)).meta(read: JSONRead)
          end
        end

        # @!parse
        #   class SQL::Attribute
        #     # @!method contain(value)
        #     #   Check whether the JSON value includes a json value
        #     #   Translates to the @> operator
        #     #
        #     #   @example
        #     #     people.where { fields.contain(gender: 'Female') }
        #     #     people.where(people[:fields].contain([name: 'age']))
        #     #     people.select { fields.contain(gender: 'Female').as(:is_female) }
        #     #
        #     #   @param [Hash,Array,Object] value
        #     #
        #     #   @return [SQL::Attribute<Types::Bool>]
        #     #
        #     #   @api public
        #
        #     # @!method contained_by(value)
        #     #   Check whether the JSON value is contained by other value
        #     #   Translates to the <@ operator
        #     #
        #     #   @example
        #     #     people.where { custom_values.contained_by(age: 25, foo: 'bar') }
        #     #
        #     #   @param [Hash,Array] value
        #     #
        #     #   @return [SQL::Attribute<Types::Bool>]
        #     #
        #     #   @api public
        #
        #     # @!method get(*path)
        #     #   Extract the JSON value using at the specified path
        #     #   Translates to -> or #> depending on the number of arguments
        #     #
        #     #   @example
        #     #     people.select { data.get('age').as(:person_age) }
        #     #     people.select { fields.get(0).as(:first_field) }
        #     #     people.select { fields.get('0', 'value').as(:first_field_value) }
        #     #
        #     #   @param [Array<Integer>,Array<String>] path Path to extract
        #     #
        #     #   @return [SQL::Attribute<Types::PG::JSON>,SQL::Attribute<Types::PG::JSONB>]
        #     #
        #     #   @api public
        #
        #     # @!method get_text(*path)
        #     #   Extract the JSON value as text using at the specified path
        #     #   Translates to ->> or #>> depending on the number of arguments
        #     #
        #     #   @example
        #     #     people.select { data.get('age').as(:person_age) }
        #     #     people.select { fields.get(0).as(:first_field) }
        #     #     people.select { fields.get('0', 'value').as(:first_field_value) }
        #     #
        #     #   @param [Array<Integer>,Array<String>] path Path to extract
        #     #
        #     #   @return [SQL::Attribute<Types::String>]
        #     #
        #     #   @api public
        #
        #     # @!method has_key(key)
        #     #   Does the JSON value have the specified top-level key
        #     #   Translates to ?
        #     #
        #     #   @example
        #     #     people.where { data.has_key('age') }
        #     #
        #     #   @param [String] key
        #     #
        #     #   @return [SQL::Attribute<Types::Bool>]
        #     #
        #     #   @api public
        #
        #     # @!method has_any_key(*keys)
        #     #   Does the JSON value have any of the specified top-level keys
        #     #   Translates to ?|
        #     #
        #     #   @example
        #     #     people.where { data.has_any_key('age', 'height') }
        #     #
        #     #   @param [Array<String>] keys
        #     #
        #     #   @return [SQL::Attribute<Types::Bool>]
        #     #
        #     #   @api public
        #
        #     # @!method has_all_keys(*keys)
        #     #   Does the JSON value have all the specified top-level keys
        #     #   Translates to ?&
        #     #
        #     #   @example
        #     #     people.where { data.has_all_keys('age', 'height') }
        #     #
        #     #   @param [Array<String>] keys
        #     #
        #     #   @return [SQL::Attribute<Types::Bool>]
        #     #
        #     #   @api public
        #
        #     # @!method merge(value)
        #     #   Concatenate two JSON values
        #     #   Translates to ||
        #     #
        #     #   @example
        #     #     people.select { data.merge(fetched_at: Time.now).as(:data) }
        #     #     people.select { (fields + [name: 'height', value: 165]).as(:fields) }
        #     #
        #     #   @param [Hash,Array] value
        #     #
        #     #   @return [SQL::Attribute<Types::PG::JSONB>]
        #     #
        #     #   @api public
        #
        #     # @!method +(value)
        #     #   An alias for SQL::Attribute<JSONB>#merge
        #     #
        #     #   @api public
        #
        #     # @!method delete(*path)
        #     #   Deletes the specified value by key, index, or path
        #     #   Translates to - or #- depending on the number of arguments
        #     #
        #     #   @example
        #     #     people.select { data.delete('age').as(:data_without_age) }
        #     #     people.select { fields.delete(0).as(:fields_without_first) }
        #     #     people.select { fields.delete(-1).as(:fields_without_last) }
        #     #     people.select { data.delete('deeply', 'nested', 'value').as(:data) }
        #     #     people.select { fields.delete('0', 'name').as(:data) }
        #     #
        #     #   @param [Array<String>] path
        #     #
        #     #   @return [SQL::Attribute<Types::PG::JSONB>]
        #     #
        #     #   @api public
        #   end
        module JSONMethods
          def self.[](type, wrap)
            parent = self
            Module.new do
              include parent
              define_method(:json_type) { type }
              define_method(:wrap, wrap)
            end
          end

          def get(_type, expr, *path)
            Attribute[json_type].meta(sql_expr: wrap(expr)[path_args(path)])
          end

          def get_text(_type, expr, *path)
            Attribute[SQL::Types::String].meta(sql_expr: wrap(expr).get_text(path_args(path)))
          end

          private

          def path_args(path)
            case path.size
            when 0 then raise ArgumentError, 'wrong number of arguments (given 0, expected 1+)'
            when 1 then path[0]
            else path
            end
          end
        end

        TypeExtensions.register(JSON) do
          include JSONMethods[JSON, :pg_json.to_proc]
        end

        TypeExtensions.register(JSONB) do
          include JSONMethods[JSONB, :pg_jsonb.to_proc]

          def contain(_type, expr, value)
            Attribute[SQL::Types::Bool].meta(sql_expr: wrap(expr).contains(value))
          end

          def contained_by(_type, expr, value)
            Attribute[SQL::Types::Bool].meta(sql_expr: wrap(expr).contained_by(value))
          end

          def has_key(_type, expr, key)
            Attribute[SQL::Types::Bool].meta(sql_expr: wrap(expr).has_key?(key))
          end

          def has_any_key(_type, expr, *keys)
            Attribute[SQL::Types::Bool].meta(sql_expr: wrap(expr).contain_any(keys))
          end

          def has_all_keys(_type, expr, *keys)
            Attribute[SQL::Types::Bool].meta(sql_expr: wrap(expr).contain_all(keys))
          end

          def merge(_type, expr, value)
            Attribute[JSONB].meta(sql_expr: wrap(expr).concat(value))
          end
          alias_method :+, :merge

          def delete(_type, expr, *path)
            sql_expr = path.size == 1 ? wrap(expr) - path : wrap(expr).delete_path(path)
            Attribute[JSONB].meta(sql_expr: sql_expr)
          end
        end
      end
    end
  end
end
