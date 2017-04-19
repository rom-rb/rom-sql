require 'dry-types'
require 'sequel'
require 'ipaddr'

Sequel.extension(*%i(pg_array pg_array_ops pg_json pg_json_ops pg_hstore))

module ROM
  module SQL
    module Types
      module PG
        # UUID

        UUID = Types::String

        # Array

        Array = Types.Definition(Sequel::Postgres::PGArray)

        def self.Array(db_type)
          Array.constructor(-> (v) { Sequel.pg_array(v, db_type) }).meta(type: db_type)
        end

        # JSON

        JSONArray = Types.Constructor(Sequel::Postgres::JSONArray, &Sequel.method(:pg_json))

        JSONHash = Types.Constructor(Sequel::Postgres::JSONArray, &Sequel.method(:pg_json))

        JSONOp = Types.Constructor(Sequel::Postgres::JSONOp, &Sequel.method(:pg_json))

        JSON = JSONArray | JSONHash | JSONOp

        # JSONB

        JSONBArray = Types.Constructor(Sequel::Postgres::JSONBArray, &Sequel.method(:pg_jsonb))

        JSONBHash = Types.Constructor(Sequel::Postgres::JSONBHash, &Sequel.method(:pg_jsonb))

        JSONBOp = Types.Constructor(Sequel::Postgres::JSONBOp, &Sequel.method(:pg_jsonb))

        JSONB = JSONBArray | JSONBHash | JSONBOp

        Attribute.register_type(JSONB) do
          def contains(type, keys)
            Sequel::Postgres::JSONBOp.new(type.meta[:name]).contains(keys)
          end
        end

        # HStore

        HStoreR = Types.Constructor(Hash, &:to_hash)
        HStore = Types.Constructor(Sequel::Postgres::HStore, &Sequel.method(:hstore)).meta(read: HStoreR)

        Bytea = Types.Constructor(Sequel::SQL::Blob, &Sequel::SQL::Blob.method(:new))

        IPAddressR = Types.Constructor(IPAddr) { |ip| IPAddr.new(ip.to_s) }

        IPAddress = Types.Constructor(IPAddr, &:to_s).meta(read: IPAddressR)

        Money = Types::Decimal

        # Geometric types

        Point = ::Struct.new(:x, :y)

        PointD = Types.Definition(Point)

        PointTR = Types.Constructor(Point) do |p|
          x, y = p.to_s[1...-1].split(',', 2)
          Point.new(Float(x), Float(y))
        end

        PointT = Types.Constructor(Point) { |p| "(#{ p.x },#{ p.y })" }.meta(read: PointTR)

        Line = ::Struct.new(:a, :b, :c)

        LineTR = Types.Constructor(Line) do |ln|
          a, b, c = ln.to_s[1..-2].split(',', 3)
          Line.new(Float(a), Float(b), Float(c))
        end

        LineT = Types.Constructor(Line) { |ln| "{#{ ln.a },#{ ln.b },#{ln.c}}"}.meta(read: LineTR)

        Circle = ::Struct.new(:center, :radius)

        CircleTR = Types.Constructor(Circle) do |c|
          x, y, r = c.to_s.tr('()<>', '').split(',', 3)
          center = Point.new(Float(x), Float(y))
          Circle.new(center, Float(r))
        end

        CircleT = Types.Constructor(Circle) { |c| "<(#{ c.center.x },#{ c.center.y }),#{ c.radius }>" }.meta(read: CircleTR)

        Box = ::Struct.new(:upper_right, :lower_left)

        BoxTR = Types.Constructor(Box) do |b|
          x_right, y_right, x_left, y_left = b.to_s.tr('()', '').split(',', 4)
          upper_right = Point.new(Float(x_right), Float(y_right))
          lower_left = Point.new(Float(x_left), Float(y_left))
          Box.new(upper_right, lower_left)
        end

        BoxT = Types.Constructor(Box) { |b| "((#{ b.upper_right.x },#{ b.upper_right.y }),(#{ b.lower_left.x },#{ b.lower_left.y }))" }.meta(read: BoxTR)

        LineSegment = ::Struct.new(:begin, :end)

        LineSegmentTR = Types.Constructor(LineSegment) do |lseg|
          x_begin, y_begin, x_end, y_end = lseg.to_s.tr('()[]', '').split(',', 4)
          point_begin = Point.new(Float(x_begin), Float(y_begin))
          point_end = Point.new(Float(x_end), Float(y_end))
          LineSegment.new(point_begin, point_end)
        end

        LineSegmentT = Types.Constructor(LineSegment) do |lseg|
          "[(#{ lseg.begin.x },#{ lseg.begin.y }),(#{ lseg.end.x },#{ lseg.end.y })]"
        end.meta(read: LineSegmentTR)

        Polygon = Types::Strict::Array.member(PointD)

        PolygonTR = Polygon.constructor do |p|
          coordinates = p.to_s.tr('()', '').split(',').each_slice(2)
          points = coordinates.map { |x, y| Point.new(Float(x), Float(y)) }
          Polygon[points]
        end

        PolygonT = PointD.constructor do |path|
          points_joined = path.map { |p| "(#{ p.x },#{ p.y })" }.join(',')
          "(#{ points_joined })"
        end.meta(read: PolygonTR)

        Path = ::Struct.new(:points, :type) do
          def open?
            type == :open
          end

          def closed?
            type == :closed
          end

          def to_a
            points
          end
        end

        PathD = Types.Definition(Path)

        PathTR = PathD.constructor do |path|
          open = path.to_s.start_with?('[') && path.to_s.end_with?(']')
          coordinates = path.to_s.tr('()[]', '').split(',').each_slice(2)
          points = coordinates.map { |x, y| Point.new(Float(x), Float(y)) }

          if open
            Path.new(points, :open)
          else
            Path.new(points, :closed)
          end
        end

        PathT = PathD.constructor do |path|
          points_joined = path.to_a.map { |p| "(#{ p.x },#{ p.y })" }.join(',')

          if path.open?
            "[#{ points_joined }]"
          else
            "(#{ points_joined })"
          end
        end.meta(read: PathTR)
      end
    end
  end
end
