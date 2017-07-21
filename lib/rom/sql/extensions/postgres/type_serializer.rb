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
            Types::Path => 'path'
          )
        )
      end
    end

    TypeSerializer.register(:postgres, Postgres::TypeSerializer.new.freeze)
  end
end
