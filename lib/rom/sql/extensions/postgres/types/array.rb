require 'sequel/core'

Sequel.extension(*%i(pg_array pg_array_ops))

module ROM
  module SQL
    module Postgres
      module Types
        Array = SQL::Types::Array

        ArrayRead = Array.constructor { |v| v.respond_to?(:to_ary) ? v.to_ary : v }

        @array_types = ::Hash.new do |hash, db_type|
          type = Array.constructor(-> (v) { Sequel.pg_array(v, db_type) }).meta(
            type: db_type, read: ArrayRead
          )
          TypeExtensions.register(type) { include ArrayMethods }
          hash[db_type] = type
        end

        def self.Array(db_type)
          @array_types[db_type]
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
        #     #   @return [SQL::Attribute<Types::Int>]
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
        #     #   @param [Object] null
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

          def any(type, expr, value)
            Attribute[SQL::Types::Bool].meta(sql_expr: { value => expr.pg_array.any })
          end

          def contained_by(type, expr, other)
            Attribute[SQL::Types::Bool].meta(sql_expr: expr.pg_array.contained_by(type[other]))
          end

          def length(type, expr)
            Attribute[SQL::Types::Int].meta(sql_expr: expr.pg_array.length)
          end

          def overlaps(type, expr, other_array)
            Attribute[SQL::Types::Bool].meta(sql_expr: expr.pg_array.overlaps(type[other_array]))
          end

          def remove_value(type, expr, value)
            Attribute[type].meta(sql_expr: expr.pg_array.remove(cast(type, value)))
          end

          def join(type, expr, delimiter = '', null = nil)
            Attribute[SQL::Types::String].meta(sql_expr: expr.pg_array.join(delimiter, null))
          end

          def +(type, expr, other)
            Attribute[type].meta(sql_expr: expr.pg_array.concat(other))
          end

          private

          def cast(type, value)
            db_type = type.optional? ? type.right.meta[:type] : type.meta[:type]
            Sequel.cast(value, db_type)
          end
        end
      end
    end
  end
end
