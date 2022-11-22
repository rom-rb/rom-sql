RSpec.describe 'ROM::SQL::Postgres::Types' do
  it 'has the correct meta db_type' do
    {
      'uuid' => ROM::SQL::Postgres::Types::UUID,
      'hstore' => ROM::SQL::Postgres::Types::HStore,
      'bytea'  => ROM::SQL::Postgres::Types::Bytea,
      'money' => ROM::SQL::Postgres::Types::Money,
      'xml' => ROM::SQL::Postgres::Types::XML,
      'inet' => ROM::SQL::Postgres::Types::IPAddress,
      'cidr' => ROM::SQL::Postgres::Types::IPNetwork,
      'json' => ROM::SQL::Postgres::Types::JSON,
      'jsonb' => ROM::SQL::Postgres::Types::JSONB,
      'point' => ROM::SQL::Postgres::Types::Point,
      'line'  => ROM::SQL::Postgres::Types::Line,
      'circle' => ROM::SQL::Postgres::Types::Circle,
      'box'   => ROM::SQL::Postgres::Types::Box,
      'lseg'  => ROM::SQL::Postgres::Types::LineSegment,
      'polygon' => ROM::SQL::Postgres::Types::Polygon,
      'path'  => ROM::SQL::Postgres::Types::Path,
      'integer[]' => ROM::SQL::Postgres::Types.Array('integer')
    }.each do |meta_type, type|
      expect(type.meta[:db_type]).to eq meta_type
    end
  end
end
