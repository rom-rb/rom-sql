require 'sequel/core'

Sequel.extension(:pg_range, :pg_range_ops)

module ROM
  module SQL
    module Postgres
      module Values
        Range = ::Struct.new(:lower, :upper, :lower_bound, :upper_bound)
      end

      module Types
        def self.Range(name, read_type)
          Type(name) do
            read = SQL::Types.Constructor(Values::Range) do |value|
              pg_range =
                if value.is_a?(Sequel::Postgres::PGRange)
                  value
                elsif value && value.respond_to?(:to_s)
                  Sequel::Postgres::PGRange::Parser.new(name, read_type)
                                                   .call(value.to_s)
                else
                  value
                end

              Values::Range.new(
                pg_range.begin,
                pg_range.end,
                pg_range.exclude_begin? ? :'(' : :'[',
                pg_range.exclude_end? ? :')' : :']'
              )
            end

            type = SQL::Types.Definition(Values::Range).constructor do |range|
              format('%s%s,%s%s',
                     range.lower_bound,
                     range.lower,
                     range.upper,
                     range.upper_bound)
            end

            type.meta(read: read)
          end
        end

        Int4Range = Range('int4range', SQL::Types::Coercible::Int)
        Int8Range = Range('int8range', SQL::Types::Coercible::Int)
        NumRange  = Range('numrange',  SQL::Types::Coercible::Int)
        TsRange   = Range('tsrange',   SQL::Types::Form::Time)
        TsTzRange = Range('tstzrange', SQL::Types::Form::Time)
        DateRange = Range('daterange', SQL::Types::Form::Date)

        module RangeOperators
          def contains(_type, expr, value)
            Attribute[SQL::Types::Bool].meta(
              sql_expr: Sequel.pg_range(expr).contains(value)
            )
          end

          def contained_by(_type, expr, value)
            Attribute[SQL::Types::Bool].meta(
              sql_expr: Sequel.pg_range(expr).contained_by(value)
            )
          end

          def overlaps(_type, expr, value)
            Attribute[SQL::Types::Bool].meta(
              sql_expr: Sequel.pg_range(expr).overlaps(value)
            )
          end

          def left_of(_type, expr, value)
            Attribute[SQL::Types::Bool].meta(
              sql_expr: Sequel.pg_range(expr).left_of(value)
            )
          end

          def right_of(_type, expr, value)
            Attribute[SQL::Types::Bool].meta(
              sql_expr: Sequel.pg_range(expr).right_of(value)
            )
          end

          def starts_after(_type, expr, value)
            Attribute[SQL::Types::Bool].meta(
              sql_expr: Sequel.pg_range(expr).starts_after(value)
            )
          end

          def ends_before(_type, expr, value)
            Attribute[SQL::Types::Bool].meta(
              sql_expr: Sequel.pg_range(expr).ends_before(value)
            )
          end

          def adjacent_to(_type, expr, value)
            Attribute[SQL::Types::Bool].meta(
              sql_expr: Sequel.pg_range(expr).adjacent_to(value)
            )
          end
        end

        module RangeFunctions
          def lower(_type, expr)
            Attribute[SQL::Types::Bool].meta(
              sql_expr: Sequel.pg_range(expr).lower
            )
          end

          def upper(_type, expr)
            Attribute[SQL::Types::Bool].meta(
              sql_expr: Sequel.pg_range(expr).upper
            )
          end

          def isempty(_type, expr)
            Attribute[SQL::Types::Bool].meta(
              sql_expr: Sequel.pg_range(expr).isempty
            )
          end

          def lower_inc(_type, expr)
            Attribute[SQL::Types::Bool].meta(
              sql_expr: Sequel.pg_range(expr).lower_inc
            )
          end

          def upper_inc(_type, expr)
            Attribute[SQL::Types::Bool].meta(
              sql_expr: Sequel.pg_range(expr).upper_inc
            )
          end

          def lower_inf(_type, expr)
            Attribute[SQL::Types::Bool].meta(
              sql_expr: Sequel.pg_range(expr).lower_inf
            )
          end

          def upper_inf(_type, expr)
            Attribute[SQL::Types::Bool].meta(
              sql_expr: Sequel.pg_range(expr).upper_inf
            )
          end
        end

        TypeExtensions.register(Int4Range) do
          include RangeOperators
          include RangeFunctions
        end

        TypeExtensions.register(Int8Range) do
          include RangeOperators
          include RangeFunctions
        end

        TypeExtensions.register(NumRange) do
          include RangeOperators
          include RangeFunctions
        end

        TypeExtensions.register(TsRange) do
          include RangeOperators
          include RangeFunctions
        end

        TypeExtensions.register(TsTzRange) do
          include RangeOperators
          include RangeFunctions
        end

        TypeExtensions.register(DateRange) do
          include RangeOperators
          include RangeFunctions
        end
      end
    end
  end
end
