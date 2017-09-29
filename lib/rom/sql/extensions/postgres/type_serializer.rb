module ROM
  module SQL
    module Postgres
      # @api private
      class TypeSerializer < ROM::SQL::TypeSerializer
        mapping(
          mapping.merge(
            SQL::Types::String => 'text',
            Types::UUID => 'uuid',
            Types::XML => 'xml',
            Types::Money => 'money',
            Types::Bytea => 'bytea',
            Types::JSON => 'json',
            Types::JSONB => 'jsonb',
            Types::HStore => 'hstore',
            Types::IPAddress => 'inet',
            Types::Point => 'point',
            Types::Line => 'line',
            Types::Circle => 'circle',
            Types::Box => 'box',
            Types::LineSegment => 'lseg',
            Types::Polygon => 'polygon',
            Types::Path => 'path',
            Types::Int4Range => 'int4range',
            Types::Int8Range => 'int8range',
            Types::NumRange => 'numrange',
            Types::TsRange => 'tsrange',
            Types::TsTzRange => 'tstzrange',
            Types::DateRange => 'daterange'
          )
        )

        def call(type)
          super do
            if type.respond_to?(:primitive) && type.primitive.equal?(Array)
              "#{ type.meta[:type] }[]"
            end
          end
        end
      end
    end

    TypeSerializer.register(:postgres, Postgres::TypeSerializer.new.freeze)
  end
end
