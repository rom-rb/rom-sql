RSpec.describe ROM::SQL::TypeSerializer[:postgres] do
  subject(:serializer) { ROM::SQL::TypeSerializer[:postgres] }

  it 'serializes PG types' do
    types = {
      'uuid'  => ROM::SQL::Postgres::Types::UUID,
      'money' => ROM::SQL::Postgres::Types::Money,
      'bytea' => ROM::SQL::Postgres::Types::Bytea,
      'json'  => ROM::SQL::Postgres::Types::JSON,
      'jsonb' => ROM::SQL::Postgres::Types::JSONB,
      'hstore' => ROM::SQL::Postgres::Types::HStore,
      'inet' => ROM::SQL::Postgres::Types::IPAddress,
      'xml' => ROM::SQL::Postgres::Types::XML,
      'point' => ROM::SQL::Postgres::Types::Point,
      'line' => ROM::SQL::Postgres::Types::Line,
      'circle' => ROM::SQL::Postgres::Types::Circle,
      'box' => ROM::SQL::Postgres::Types::Box,
      'lseg' => ROM::SQL::Postgres::Types::LineSegment,
      'polygon' => ROM::SQL::Postgres::Types::Polygon,
      'path' => ROM::SQL::Postgres::Types::Path,
      'ltree' => ROM::SQL::Postgres::Types::Ltree,
      'text[]' => ROM::SQL::Postgres::Types::Array('text')
    }

    types.each do |db_type, rom_type|
      expect(serializer.(rom_type)).to eql(db_type)
    end
  end
end
