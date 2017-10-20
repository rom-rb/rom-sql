RSpec.describe ROM::SQL::Gateway, :postgres, :helpers do
  include_context 'database setup'

  before do
    conn.drop_table?(:test_pg_types)

    conn.execute('create extension if not exists hstore')
  end

  let(:table_name) { :test_pg_types }

  subject(:gateway) { container.gateways[:default] }

  let(:source) { ROM::Relation::Name[:test_pg_types] }

  let(:inferrer) { ROM::SQL::Schema::Inferrer.new }

  subject(:migrated_schema) do
    empty = define_schema(table_name)
    empty.with(inferrer.(empty, gateway))
  end

  describe 'common types' do
    before do
      conf.relation(:test_pg_types) do
        schema do
          attribute :id,              ROM::SQL::Types::Serial
          attribute :string,          ROM::SQL::Types::String
          attribute :int,             ROM::SQL::Types::Int
          attribute :time,            ROM::SQL::Types::Time
          attribute :date,            ROM::SQL::Types::Date
          attribute :decimal,         ROM::SQL::Types::Decimal
          attribute :string_nullable, ROM::SQL::Types::String.optional
          attribute :jsonb,           ROM::SQL::Types::PG::JSONB
          attribute :json,            ROM::SQL::Types::PG::JSON
          attribute :tags,            ROM::SQL::Types::PG::Array('text')
          attribute :money,           ROM::SQL::Types::PG::Money
          attribute :uuid,            ROM::SQL::Types::PG::UUID
          attribute :bytea,           ROM::SQL::Types::PG::Bytea
          attribute :hstore,          ROM::SQL::Types::PG::HStore
          attribute :inet,            ROM::SQL::Types::PG::IPAddress
          attribute :xml,             ROM::SQL::Types::PG::XML
          attribute :point,           ROM::SQL::Types::PG::Point
          attribute :line,            ROM::SQL::Types::PG::Line
          attribute :circle,          ROM::SQL::Types::PG::Circle
          attribute :box,             ROM::SQL::Types::PG::Box
          attribute :lseg,            ROM::SQL::Types::PG::LineSegment
          attribute :polygon,         ROM::SQL::Types::PG::Polygon
          attribute :path,            ROM::SQL::Types::PG::Path
          attribute :int4range,       ROM::SQL::Types::PG::Int4Range
          attribute :int8range,       ROM::SQL::Types::PG::Int8Range
          attribute :numrange,        ROM::SQL::Types::PG::NumRange
          attribute :tsrange,         ROM::SQL::Types::PG::TsRange
          attribute :tstzrange,       ROM::SQL::Types::PG::TsTzRange
          attribute :daterange,       ROM::SQL::Types::PG::DateRange
        end
      end
    end

    it 'has support for PG data types' do
      gateway.auto_migrate!(conf, inline: true)

      expect(migrated_schema.to_h).
        to eql(
             attributes(
               id: ROM::SQL::Types::Int.meta(primary_key: true),
               string: ROM::SQL::Types::String,
               int: ROM::SQL::Types::Int,
               time: ROM::SQL::Types::Time,
               date: ROM::SQL::Types::Date,
               decimal: ROM::SQL::Types::Decimal,
               string_nullable: ROM::SQL::Types::String.optional,
               jsonb: ROM::SQL::Types::PG::JSONB,
               json: ROM::SQL::Types::PG::JSON,
               tags: ROM::SQL::Types::PG::Array('text'),
               money: ROM::SQL::Types::PG::Money,
               uuid: ROM::SQL::Types::PG::UUID,
               bytea: ROM::SQL::Types::PG::Bytea,
               hstore: ROM::SQL::Types::PG::HStore,
               inet: ROM::SQL::Types::PG::IPAddress,
               xml: ROM::SQL::Types::PG::XML,
               point: ROM::SQL::Types::PG::Point,
               line: ROM::SQL::Types::PG::Line,
               circle: ROM::SQL::Types::PG::Circle,
               box: ROM::SQL::Types::PG::Box,
               lseg: ROM::SQL::Types::PG::LineSegment,
               polygon: ROM::SQL::Types::PG::Polygon,
               path: ROM::SQL::Types::PG::Path,
               int4range: ROM::SQL::Types::PG::Int4Range,
               int8range: ROM::SQL::Types::PG::Int8Range,
               numrange: ROM::SQL::Types::PG::NumRange,
               tsrange: ROM::SQL::Types::PG::TsRange,
               tstzrange: ROM::SQL::Types::PG::TsTzRange,
               daterange: ROM::SQL::Types::PG::DateRange
             )
           )
    end
  end
end
