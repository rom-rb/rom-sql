# frozen_string_literal: true

require 'sequel/core'

Sequel.extension(:pg_range, :pg_range_ops)

module ROM
  module SQL
    module Postgres
      module Values
        Range = ::Struct.new(:lower, :upper, :bounds) do
          PAREN_LEFT  = '('.freeze
          PAREN_RIGHT = ')'.freeze

          def initialize(lower, upper, bounds = :'[)')
            super
          end

          def exclude_begin?
            bounds[0] == PAREN_LEFT
          end

          def exclude_end?
            bounds[1] == PAREN_RIGHT
          end
        end
      end

      # @api public
      module Types
        # The list of range types supported by PostgreSQL
        # @see https://www.postgresql.org/docs/current/static/rangetypes.html

        @range_parsers = {
          int4range: Sequel::Postgres::PGRange::Parser.new(
            'int4range', SQL::Types::Coercible::Integer
          ),
          int8range: Sequel::Postgres::PGRange::Parser.new(
            'int8range', SQL::Types::Coercible::Integer
          ),
          numrange:  Sequel::Postgres::PGRange::Parser.new(
            'numrange', SQL::Types::Coercible::Integer
          ),
          tsrange:   Sequel::Postgres::PGRange::Parser.new(
            'tsrange', ::Time.method(:parse)
          ),
          tstzrange: Sequel::Postgres::PGRange::Parser.new(
            'tstzrange', ::Time.method(:parse)
          ),
          daterange: Sequel::Postgres::PGRange::Parser.new(
            'daterange', ::Date.method(:parse)
          )
        }.freeze

        # @api private
        def self.range_read_type(name)
          SQL::Types.Constructor(Values::Range) do |value|
            pg_range =
              if value.is_a?(Sequel::Postgres::PGRange)
                value
              elsif value && value.respond_to?(:to_s)
                @range_parsers[name].(value.to_s)
              else
                value
              end

            Values::Range.new(
              pg_range.begin,
              pg_range.end,
              [pg_range.exclude_begin? ? :'(' : :'[',
               pg_range.exclude_end? ? :')' : :']']
              .join('').to_sym
            )
          end
        end

        # @api private
        def self.range(name, read_type)
          Type(name) do
            type = SQL::Types.Nominal(Values::Range).constructor do |range|
              format('%s%s,%s%s',
                     range.exclude_begin? ? :'(' : :'[',
                     range.lower,
                     range.upper,
                     range.exclude_end? ? :')' : :']')
            end

            type.meta(read: read_type)
          end
        end

        Int4Range = range('int4range', range_read_type(:int4range))
        Int8Range = range('int8range', range_read_type(:int8range))
        NumRange  = range('numrange',  range_read_type(:numrange))
        TsRange   = range('tsrange',   range_read_type(:tsrange))
        TsTzRange = range('tstzrange', range_read_type(:tstzrange))
        DateRange = range('daterange', range_read_type(:daterange))

        module RangeOperators
          def contain(_type, expr, value)
            Attribute[SQL::Types::Bool].meta(
              sql_expr: Sequel.pg_range(expr).contains(value)
            )
          end

          def contained_by(_type, expr, value)
            Attribute[SQL::Types::Bool].meta(
              sql_expr: Sequel.pg_range(expr).contained_by(value)
            )
          end

          def overlap(_type, expr, value)
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

          def is_empty(_type, expr)
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

        [
          Int4Range,
          Int8Range,
          NumRange,
          TsRange,
          TsTzRange,
          DateRange
        ].each do |type|
          TypeExtensions.register(type) do
            include RangeOperators
            include RangeFunctions
          end
        end
      end
    end
  end
end
