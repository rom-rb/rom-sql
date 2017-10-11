RSpec.describe 'ROM::SQL::Schema::PostgresInferrer', :postgres do
  include_context 'database setup'

  before do
    inferrable_relations.concat %i(test_inferrence)
  end

  colors = %w(red orange yellow green blue purple)

  before do
    conn.extension :pg_enum

    conn.execute('create extension if not exists hstore')
    conn.drop_table?(:test_inferrence)
    conn.drop_enum(:rainbow, if_exists: true)

    conn.create_enum(:rainbow, colors)

    conn.create_table :test_inferrence do
      primary_key :id, :uuid
      bigint :big
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
      circle :circle
      box :box
      lseg :lseg
      polygon :polygon
      path :path
      timestamp :created_at
      column :datetime, "timestamp(0) without time zone"
      column :datetime_tz, "timestamp(0) with time zone"
      boolean :flag, null: false
    end
  end

  let(:schema) { container.relations[:test_inferrence].schema }
  let(:source) { container.relations[:test_inferrence].name }

  context 'inferring db-specific attributes' do
    before do
      conf.relation(:test_inferrence) do
        schema(infer: true)
      end
    end

    it 'can infer attributes for dataset' do
      expect(schema.to_h).
        to eql(
             id: ROM::SQL::Types::PG::UUID.meta(name: :id, source: source, primary_key: true),
             big: ROM::SQL::Types::Int.optional.meta(name: :big, source: source),
             json_data: ROM::SQL::Types::PG::JSON.optional.meta(name: :json_data, source: source),
             jsonb_data: ROM::SQL::Types::PG::JSONB.optional.meta(name: :jsonb_data, source: source),
             money: ROM::SQL::Types::Decimal.meta(name: :money, source: source),
             tags: ROM::SQL::Types::PG::Array('text').optional.meta(name: :tags, source: source),
             tag_ids: ROM::SQL::Types::PG::Array('bigint').optional.meta(name: :tag_ids, source: source),
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
             ),
             circle: ROM::SQL::Types::PG::CircleT.optional.meta(
               name: :circle,
               source: source,
               read: ROM::SQL::Types::PG::CircleTR.optional
             ),
             box: ROM::SQL::Types::PG::BoxT.optional.meta(
               name: :box,
               source: source,
               read: ROM::SQL::Types::PG::BoxTR.optional
             ),
             lseg: ROM::SQL::Types::PG::LineSegmentT.optional.meta(
               name: :lseg,
               source: source,
               read: ROM::SQL::Types::PG::LineSegmentTR.optional
             ),
             polygon: ROM::SQL::Types::PG::PolygonT.optional.meta(
               name: :polygon,
               source: source,
               read: ROM::SQL::Types::PG::PolygonTR.optional
             ),
             path: ROM::SQL::Types::PG::PathT.optional.meta(
               name: :path,
               source: source,
               read: ROM::SQL::Types::PG::PathTR.optional
             ),
             created_at: ROM::SQL::Types::Time.optional.meta(name: :created_at, source: source),
             datetime: ROM::SQL::Types::Time.optional.meta(name: :datetime, source: source),
             datetime_tz: ROM::SQL::Types::Time.optional.meta(name: :datetime_tz, source: source),
             flag: ROM::SQL::Types::Bool.meta(name: :flag, source: source)
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
      conn.execute('create extension if not exists hstore')

      conn.create_table(:test_bidirectional) do
        primary_key :id
        inet :ip
        point :center
        hstore :mapping
        line :line
        circle :circle
        box :box
        lseg :lseg
        polygon :polygon
        path :closed_path
        path :open_path
      end

      conf.relation(:test_bidirectional) { schema(infer: true) }

      conf.commands(:test_bidirectional) do
        define(:create) do
          result :one
        end
      end
    end

    let(:point) { ROM::SQL::Types::PG::Point.new(7.5, 30.5) }
    let(:point_2) { ROM::SQL::Types::PG::Point.new(8.5, 35.5) }
    let(:line) { ROM::SQL::Types::PG::Line.new(2.3, 4.9, 3.1415) }
    let(:dns) { IPAddr.new('8.8.8.8') }
    let(:mapping) { Hash['hot' => 'cold'] }
    let(:circle) { ROM::SQL::Types::PG::Circle.new(point, 1.0) }
    let(:lseg) { ROM::SQL::Types::PG::LineSegment.new(point, point_2) }
    let(:box_corrected) { ROM::SQL::Types::PG::Box.new(point_2, point) }
    let(:box) do
      upper_left = ROM::SQL::Types::PG::Point.new(point.x, point_2.y)
      lower_right = ROM::SQL::Types::PG::Point.new(point_2.x, point.y)

      ROM::SQL::Types::PG::Box.new(upper_left, lower_right)
    end
    let(:polygon) { ROM::SQL::Types::PG::Polygon[[point, point_2]] }
    let(:closed_path) { ROM::SQL::Types::PG::Path.new([point, point_2], :closed) }
    let(:open_path) { ROM::SQL::Types::PG::Path.new([point, point_2], :open) }

    let(:relation) { container.relations[:test_bidirectional] }
    let(:create) { commands[:test_bidirectional].create }

    it 'writes and reads data & corrects data' do
      # Box coordinates are reordered if necessary
      inserted = create.call(
        id: 1, center: point, ip: dns, mapping: mapping,
        line: line, circle: circle, lseg: lseg, box: box,
        polygon: polygon, closed_path: closed_path, open_path: open_path
      )
      expect(inserted).
        to eql(
             id: 1, center: point, ip: dns, mapping: mapping,
             line: line, circle: circle, lseg: lseg, box: box_corrected,
             polygon: polygon, closed_path: closed_path, open_path: open_path
           )
      expect(relation.to_a).to eql([inserted])
    end
  end
end
