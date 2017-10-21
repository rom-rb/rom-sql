require 'sequel/core'

Sequel.extension(*%i(pg_array pg_array_ops))

module ROM
  module SQL
    module Postgres
      module Types
        Array = SQL::Types::Array

        ArrayRead = Array.constructor { |v| v.respond_to?(:to_ary) ? v.to_ary : v }

        # @api private
        class ArrayTypes
          attr_reader :elements

          attr_reader :constructor

          attr_reader :base_write_type

          attr_reader :base_read_type

          def initialize
            @elements = {}
            @base_write_type = Postgres::Types::Array
            @base_read_type = ArrayRead
            @constructor = proc { |db_type, member|
              -> arr {
                if member
                  Sequel.pg_array(arr.map { |v| member[v] }, db_type)
                else
                  Sequel.pg_array(arr, db_type)
                end
              }
            }
          end

          def [](db_type, member_type = nil)
            elements.fetch(db_type) do
              name = "#{db_type}[]"

              write_array =
                if member_type
                  base_write_type.constructor(constructor[db_type, member_type])
                else
                  base_write_type.constructor(constructor[db_type])
                end

              read_array =
                if member_type && member_type.meta[:read]
                  base_read_type.of(member_type.meta[:read])
                else
                  base_read_type
                end

              array_type = Types.Type(name, write_array).
                             meta(type: db_type, read: read_array)

              TypeExtensions.register(array_type) { include ArrayMethods }

              elements[db_type] = array_type
            end
          end
        end

        # @api private
        def self.array_types
          @array_types ||= ArrayTypes.new
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
