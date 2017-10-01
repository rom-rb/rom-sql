require 'sequel/core'

Sequel.extension(:pg_range)

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
      end
    end
  end
end
