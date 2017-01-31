RSpec.describe 'ROM::SQL::Schema::PostgresInferrer', :postgres do
  include_context 'database setup'

  colors = %w(red orange yellow green blue purple)

  before do
    conn.extension :pg_enum

    conn.execute('create extension if not exists hstore')
    conn.drop_table?(:test_inferrence)
    conn.drop_enum(:rainbow, if_exists: true)

    conn.create_enum(:rainbow, colors)

    conn.create_table :test_inferrence do
      primary_key :id, :uuid
      Json :json_data
      Jsonb :jsonb_data
      Decimal :money, null: false
      column :tags, "text[]"
      column :tag_ids, "bigint[]"
      column :ip, "inet"
      column :subnet, "cidr"
      column :hw_address, "macaddr"
      rainbow :color
      point :center
      xml :page
      hstore :mapping
      line :line
    end
  end

  after do
    conn.drop_table?(:test_inferrence)
  end

  let(:dataset) { :test_inferrence }

  let(:schema) { container.relations[dataset].schema }

  context 'inferring db-specific attributes' do
    before do
      dataset = self.dataset
      conf.relation(dataset) do
        schema(dataset, infer: true)
      end
    end

    it 'can infer attributes for dataset' do
      source = container.relations[:test_inferrence].name

      expect(schema.to_h).to eql(
        id: ROM::SQL::Types::PG::UUID.meta(name: :id, source: source, primary_key: true),
        json_data: ROM::SQL::Types::PG::JSON.optional.meta(name: :json_data, source: source),
        jsonb_data: ROM::SQL::Types::PG::JSONB.optional.meta(name: :jsonb_data, source: source),
        money: ROM::SQL::Types::Decimal.meta(name: :money, source: source),
        tags: ROM::SQL::Types::PG::Array('text').optional.meta(name: :tags, source: source),
        tag_ids: ROM::SQL::Types::PG::Array('biging').optional.meta(name: :tag_ids, source: source),
        color: ROM::SQL::Types::String.enum(*colors).optional.meta(name: :color, source: source),
        ip: ROM::SQL::Types::PG::IPAddress.optional.meta(
          name: :ip,
          source: source,
          read: ROM::SQL::Types::PG::IPAddressR.optional
        ),
        subnet: ROM::SQL::Types::PG::IPAddress.optional.meta(
          name: :subnet,
          source: source,
          read: ROM::SQL::Types::PG::IPAddressR.optional
        ),
        hw_address: ROM::SQL::Types::String.optional.meta(name: :hw_address, source: source),
        center: ROM::SQL::Types::PG::PointT.optional.meta(
          name: :center,
          source: source,
          read: ROM::SQL::Types::PG::PointTR.optional
        ),
        page: ROM::SQL::Types::String.optional.meta(name: :page, source: source),
        mapping: ROM::SQL::Types::PG::HStore.optional.meta(
          name: :mapping,
          source: source,
          read: ROM::SQL::Types::PG::HStoreR.optional
        ),
        line: ROM::SQL::Types::PG::LineT.optional.meta(
          name: :line,
          source: source,
          read: ROM::SQL::Types::PG::LineTR.optional
        )
      )
    end
  end

  context 'with a table without columns' do
    before do
      conn.create_table(:dummy) unless conn.table_exists?(:dummy)
      conf.relation(:dummy) { schema(infer: true) }
    end

    it 'does not fail with a weird error when a relation does not have attributes' do
      expect(container.relations[:dummy].schema).to be_empty
    end
  end

  context 'with a column with bi-directional mapping' do
    before do
      conn.drop_table?(:test_bidirectional)
      conn.execute('create extension if not exists hstore')

      conn.create_table(:test_bidirectional) do
        primary_key :id
        inet :ip
        point :center
        hstore :mapping
        line :line
      end

      conf.relation(:test_bidirectional) { schema(infer: true) }

      conf.commands(:test_bidirectional) do
        define(:create) do
          result :one
        end
      end
    end

    let(:point) { ROM::SQL::Types::PG::Point.new(7.5, 30.5) }
    let(:line) { ROM::SQL::Types::PG::Line.new(2.3, 4.9, 3.1415) }
    let(:dns) { IPAddr.new('8.8.8.8') }
    let(:mapping) { Hash['hot' => 'cold'] }

    let(:relation) { container.relations[:test_bidirectional] }
    let(:create) { commands[:test_bidirectional].create }

    it 'writes and reads data' do
      inserted = create.call(id: 1, center: point, ip: dns, mapping: mapping, line: line)
      expect(inserted).to eql(id: 1, center: point, ip: dns, mapping: mapping, line: line)
      expect(relation.to_a).to eql([inserted])
    end
  end
end
