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
      rainbow :color
      column :subnet, "cidr"
      column :hw_address, "macaddr"
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

  def qualified(schema)
    schema.each_with_object({}) do |(key, type), acc|
      if type.optional?
        attr = ROM::SQL::Attribute.new(type.right).optional
      else
        attr = ROM::SQL::Attribute.new(type)
      end

      acc[key] = attr.meta(name: type.meta[:name], source: source).qualified
    end
  end

  context 'inferring db-specific attributes' do
    before do
      conf.relation(:test_inferrence) do
        schema(infer: true)
      end
    end

    it 'can infer attributes for dataset' do
      expect(schema.to_h).
        to eql(
             qualified(
               id: ROM::SQL::Types::PG::UUID.meta(name: :id, primary_key: true),
               big: ROM::SQL::Types::Int.optional.meta(name: :big),
               json_data: ROM::SQL::Types::PG::JSON.optional.meta(name: :json_data),
               jsonb_data: ROM::SQL::Types::PG::JSONB.optional.meta(name: :jsonb_data),
               money: ROM::SQL::Types::Decimal.meta(name: :money),
               tags: ROM::SQL::Types::PG::Array('text').optional.meta(name: :tags),
               tag_ids: ROM::SQL::Types::PG::Array('bigint').optional.meta(name: :tag_ids),
               ip: ROM::SQL::Types::PG::IPAddress.optional.meta(name: :ip),
               color: ROM::SQL::Types::String.enum(*colors).optional.meta(name: :color),
               subnet: ROM::SQL::Types::PG::IPAddress.optional.meta(name: :subnet),
               hw_address: ROM::SQL::Types::String.optional.meta(name: :hw_address),
               center: ROM::SQL::Types::PG::PointT.optional.meta(name: :center),
               page: ROM::SQL::Types::String.optional.meta(name: :page),
               mapping: ROM::SQL::Types::PG::HStore.optional.meta(name: :mapping),
               line: ROM::SQL::Types::PG::LineT.optional.meta(name: :line),
               circle: ROM::SQL::Types::PG::CircleT.optional.meta(name: :circle),
               box: ROM::SQL::Types::PG::BoxT.optional.meta(name: :box),
               lseg: ROM::SQL::Types::PG::LineSegmentT.optional.meta(name: :lseg),
               polygon: ROM::SQL::Types::PG::PolygonT.optional.meta(name: :polygon),
               path: ROM::SQL::Types::PG::PathT.optional.meta(name: :path),
               created_at: ROM::SQL::Types::Time.optional.meta(name: :created_at),
               datetime: ROM::SQL::Types::Time.optional.meta(name: :datetime),
               datetime_tz: ROM::SQL::Types::Time.optional.meta(name: :datetime_tz),
               flag: ROM::SQL::Types::Bool.meta(name: :flag)
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
