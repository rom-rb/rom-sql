# frozen_string_literal: true

require 'sequel/core'

Sequel.extension(:pg_array, :pg_array_ops)

require 'rom/sql/extensions/postgres/types/array_types'

module ROM
  module SQL
    module Postgres
      module Types
        Array = SQL::Types::Array

        ArrayRead = Array.constructor { |v| v.respond_to?(:to_ary) ? v.to_ary : v }

        # @api private
        def self.array_types
          @array_types ||= ArrayTypes.new(Postgres::Types::Array, Postgres::Types::ArrayRead)
        end

        # @api private
        def self.Array(db_type, member_type = nil)
          array_types[db_type, member_type]
        end

        # @!parse
        #   class SQL::Attribute
        #     # @!method contain(other)
        #     #   Check whether the array includes another array
        #     #   Translates to the @> operator
        #     #
        #     #   @param [Array] other
        #     #
        #     #   @return [SQL::Attribute<Types::Bool>]
        #     #
        #     #   @api public
        #
        #     # @!method get(idx)
        #     #   Get element by index (PG uses 1-based indexing)
        #     #
        #     #   @param [Integer] idx
        #     #
        #     #   @return [SQL::Attribute]
        #     #
        #     #   @api public
        #
        #     # @!method any(value)
        #     #   Check whether the array includes a value
        #     #   Translates to the ANY operator
        #     #
        #     #   @param [Object] value
        #     #
        #     #   @return [SQL::Attribute<Types::Bool>]
        #     #
        #     #   @api public
        #
        #     # @!method contained_by(other)
        #     #   Check whether the array is contained by another array
        #     #   Translates to the <@ operator
        #     #
        #     #   @param [Array] other
        #     #
        #     #   @return [SQL::Attribute<Types::Bool>]
        #     #
        #     #   @api public
        #
        #     # @!method length
        #     #   Return array size
        #     #
        #     #   @return [SQL::Attribute<Types::Integer>]
        #     #
        #     #   @api public
        #
        #     # @!method overlaps(other)
        #     #   Check whether the arrays have common values
        #     #   Translates to &&
        #     #
        #     #   @param [Array] other
        #     #
        #     #   @return [SQL::Attribute<Types::Bool>]
        #     #
        #     #   @api public
        #
        #     # @!method remove_value(value)
        #     #   Remove elements by value
        #     #
        #     #   @param [Object] value
        #     #
        #     #   @return [SQL::Attribute<Types::PG::Array>]
        #     #
        #     #   @api public
        #
        #     # @!method join(delimiter, null_repr)
        #     #   Convert the array to a string by joining
        #     #   values with a delimiter (empty stirng by default)
        #     #   and optional filler for NULL values
        #     #   Translates to an `array_to_string` call
        #     #
        #     #   @param [Object] delimiter
        #     #   @param [Object] null_repr
        #     #
        #     #   @return [SQL::Attribute<Types::String>]
        #     #
        #     #   @api public
        #
        #     # @!method +(other)
        #     #   Concatenate two arrays
        #     #
        #     #   @param [Array] other
        #     #
        #     #   @return [SQL::Attribute<Types::PG::Array>]
        #     #
        #     #   @api public
        #   end
        module ArrayMethods
          def contain(type, expr, other)
            Attribute[SQL::Types::Bool].meta(sql_expr: expr.pg_array.contains(type[other]))
          end

          def get(type, expr, idx)
            Attribute[type].meta(sql_expr: expr.pg_array[idx])
          end

          def any(_type, expr, value)
            Attribute[SQL::Types::Bool].meta(sql_expr: { value => expr.pg_array.any })
          end

          def contained_by(type, expr, other)
            Attribute[SQL::Types::Bool].meta(sql_expr: expr.pg_array.contained_by(type[other]))
          end

          def length(_type, expr)
            Attribute[SQL::Types::Integer].meta(sql_expr: expr.pg_array.length)
          end

          def overlaps(type, expr, other_array)
            Attribute[SQL::Types::Bool].meta(sql_expr: expr.pg_array.overlaps(type[other_array]))
          end

          def remove_value(type, expr, value)
            Attribute[type].meta(sql_expr: expr.pg_array.remove(cast(type, value)))
          end

          def join(_type, expr, delimiter = '', null = nil)
            Attribute[SQL::Types::String].meta(sql_expr: expr.pg_array.join(delimiter, null))
          end

          def +(type, expr, other)
            Attribute[type].meta(sql_expr: expr.pg_array.concat(other))
          end

          private

          def cast(type, value)
            Sequel.cast(value, type.meta[:type])
          end
        end
      end
    end
  end
end
