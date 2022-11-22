# frozen_string_literal: true

RSpec.describe "ROM::SQL::Schema::PostgresInferrer", :postgres, :helpers do
  include_context "database setup"

  before do
    inferrable_relations.concat %i[test_inferrence]
  end

  colors = %w[red orange yellow green blue purple]

  before do
    conn.execute("create extension if not exists hstore")
    conn.execute("create extension if not exists ltree")

    conn.extension :pg_enum
    conn.extension :pg_hstore
    conn.drop_table?(:test_inferrence)
    conn.drop_enum(:rainbow, if_exists: true)

    conn.create_enum(:rainbow, colors)

    conn.create_table :test_inferrence do
      uuid :id, primary_key: true
      bigint :big
      Json :json_data
      Jsonb :jsonb_data
      money :money, null: false
      decimal :decimal, null: false
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
      ltree :ltree_path
      timestamp :created_at
      column :datetime, "timestamp(0) without time zone"
      column :datetime_tz, "timestamp(0) with time zone"
      boolean :flag, null: false
      int4range :int4range
      int8range :int8range
      numrange  :numrange
      tsrange   :tsrange
      tstzrange :tstzrange
      daterange :daterange
    end
  end

  let(:gateway) { container.gateways[:default] }

  let(:source) { ROM::Relation::Name[:test_inferrence] }

  let(:inferrer) { ROM::SQL::Schema::Inferrer.new }

  subject(:schema) do
    empty = define_schema(:test_inferrence)
    empty.with(**inferrer.(empty, gateway))
  end

  context "when pg_enum in primary key" do
    before do
      conn.drop_table?(:test_inferrence)
      conn.create_table(:test_inferrence) do
        column :colours, :rainbow
        primary_key [:colours]
      end
    end

    it "can infer primary key on enum column" do
      expect(schema.to_h).to eql(attributes(
                                   colours: ROM::SQL::Types::String.enum(*colors).meta(primary_key: true)
                                 ))
    end
  end

  context "inferring db-specific attributes" do
    let(:expected) do
      attributes(
        id: define_attribute(:id, ROM::SQL::Types::PG::UUID, primary_key: true),
        big: define_attribute(:big, ROM::SQL::Types::Integer.optional, source: source),
        json_data: define_attribute(:json_data, ROM::SQL::Types::PG::JSON.optional, source: source),
        jsonb_data: define_attribute(:jsonb_data, ROM::SQL::Types::PG::JSONB.optional, source: source),
        money: define_attribute(:money, ROM::SQL::Types::PG::Money, source: source),
        decimal: define_attribute(:decimal, ROM::SQL::Types::Decimal, source: source),
        tags: define_attribute(:tags, ROM::SQL::Types::PG::Array("text").optional, source: source),
        tag_ids: define_attribute(:tag_ids, ROM::SQL::Types::PG::Array("bigint").optional, source: source),
        ip: define_attribute(:ip, ROM::SQL::Types::PG::IPAddress.optional, source: source),
        color: define_attribute(:color, ROM::SQL::Types::String.enum(*colors).optional, source: source),
        subnet: define_attribute(:subnet, ROM::SQL::Types::PG::IPNetwork.optional, source: source),
        hw_address: define_attribute(:hw_address, ROM::SQL::Types::String.optional, source: source),
        center: define_attribute(:center, ROM::SQL::Types::PG::Point.optional, source: source),
        page: define_attribute(:page, ROM::SQL::Types::PG::XML.optional, source: source),
        mapping: define_attribute(:mapping, ROM::SQL::Types::PG::HStore.optional, source: source),
        line: define_attribute(:line, ROM::SQL::Types::PG::Line.optional, source: source),
        circle: define_attribute(:circle, ROM::SQL::Types::PG::Circle.optional, source: source),
        box: define_attribute(:box, ROM::SQL::Types::PG::Box.optional, source: source),
        lseg: define_attribute(:lseg, ROM::SQL::Types::PG::LineSegment.optional, source: source),
        polygon: define_attribute(:polygon, ROM::SQL::Types::PG::Polygon.optional, source: source),
        path: define_attribute(:path, ROM::SQL::Types::PG::Path.optional, source: source),
        ltree_path: define_attribute(:ltree_path, ROM::SQL::Types::PG::LTree.optional, source: source),
        created_at: define_attribute(:created_at, ROM::SQL::Types::Time.optional, source: source),
        datetime: define_attribute(:datetime, ROM::SQL::Types::Time.optional, source: source),
        datetime_tz: define_attribute(:datetime_tz, ROM::SQL::Types::Time.optional, source: source),
        flag: define_attribute(:flag, ROM::SQL::Types::Bool, source: source),
        int4range: define_attribute(:int4range, ROM::SQL::Types::PG::Int4Range.optional, source: source),
        int8range: define_attribute(:int8range, ROM::SQL::Types::PG::Int8Range.optional, source: source),
        numrange: define_attribute(:numrange, ROM::SQL::Types::PG::NumRange.optional, source: source),
        tsrange: define_attribute(:tsrange, ROM::SQL::Types::PG::TsRange.optional, source: source),
        tstzrange: define_attribute(:tstzrange, ROM::SQL::Types::PG::TsTzRange.optional, source: source),
        daterange: define_attribute(:daterange, ROM::SQL::Types::PG::DateRange.optional, source: source)
      )
    end

    it "can infer attributes for dataset" do
      expected.each do |name, attribute|
        expect(schema[name]).to eql(attribute)
      end
    end
  end

  context "with a table without columns" do
    before do
      conn.create_table(:dummy) unless conn.table_exists?(:dummy)
      conf.relation(:dummy) { schema(infer: true) }
    end

    it "does not fail with a weird error when a relation does not have attributes" do
      expect(container.relations[:dummy].schema).to be_empty
    end
  end

  context "with a column with bi-directional mapping" do
    before do
      conn.execute("create extension if not exists hstore")
      conn.execute("create extension if not exists ltree")

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
        int4range :int4range
        int8range :int8range
        numrange :numrange
        tsrange :tsrange
        tstzrange :tstzrange
        daterange :daterange
        ltree :ltree_path
      end

      conf.relation(:test_bidirectional) { schema(infer: true) }

      conf.commands(:test_bidirectional) do
        define(:create) do
          config.result = :one
        end
      end
    end

    let(:values) { ROM::SQL::Postgres::Values }

    let(:point) { ROM::SQL::Postgres::Values::Point.new(7.5, 30.5) }
    let(:point_2) { ROM::SQL::Postgres::Values::Point.new(8.5, 35.5) }
    let(:line) { ROM::SQL::Postgres::Values::Line.new(2.3, 4.9, 3.1415) }
    let(:dns) { IPAddr.new("8.8.8.8") }
    let(:mapping) { {"hot" => "cold"} }
    let(:circle) { ROM::SQL::Postgres::Values::Circle.new(point, 1.0) }
    let(:lseg) { ROM::SQL::Postgres::Values::LineSegment.new(point, point_2) }
    let(:box_corrected) { ROM::SQL::Postgres::Values::Box.new(point_2, point) }
    let(:box) do
      upper_left = ROM::SQL::Postgres::Values::Point.new(point.x, point_2.y)
      lower_right = ROM::SQL::Postgres::Values::Point.new(point_2.x, point.y)

      ROM::SQL::Postgres::Values::Box.new(upper_left, lower_right)
    end
    let(:polygon) { [point, point_2] }
    let(:closed_path) { ROM::SQL::Postgres::Values::Path.new([point, point_2], :closed) }
    let(:open_path) { ROM::SQL::Postgres::Values::Path.new([point, point_2], :open) }
    let(:ltree) { ROM::Types::Values::TreePath.new("Top.Countries.Europe.Russia") }

    let(:int4range) { values::Range.new(0, 2, :"[)") }
    let(:int8range) { values::Range.new(5, 7, :"[)") }
    let(:numrange)  { values::Range.new(3, 9, :"[)") }

    let(:tsrange)   do
      timestamp = Time.parse("2017-09-25 07:00:00")
      values::Range.new(timestamp, timestamp + (3600 * 8), :"[)")
    end

    let(:tstzrange) do
      timestamp = Time.parse("2017-09-25 07:00:00 +0000")
      values::Range.new(timestamp, timestamp + (3600 * 8), :"[)")
    end

    let(:daterange) do
      values::Range.new(Date.today, Date.today.next_day, :"[)")
    end

    let(:relation) { container.relations[:test_bidirectional] }
    let(:create) { commands[:test_bidirectional][:create] }

    it "writes and reads data & corrects data" do
      # Box coordinates are reordered if necessary
      inserted = create.(
        id: 1, center: point, ip: dns, mapping: mapping,
        line: line, circle: circle, lseg: lseg, box: box,
        polygon: polygon, closed_path: closed_path, open_path: open_path,
        int4range: int4range, int8range: int8range, numrange: numrange,
        tsrange: tsrange, tstzrange: tstzrange, daterange: daterange,
        ltree_path: ltree
      )

      expect(inserted).to eql(
        id: 1, center: point, ip: dns, mapping: mapping,
        line: line, circle: circle, lseg: lseg, box: box_corrected,
        polygon: polygon, closed_path: closed_path, open_path: open_path,
        int4range: int4range, int8range: int8range, numrange: numrange,
        tsrange: tsrange, tstzrange: tstzrange, daterange: daterange,
        ltree_path: ltree
      )
    end
  end
end
