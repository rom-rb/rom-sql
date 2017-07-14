module ROM
  module SQL
    module Postgres
      module Types
        Point = ::Struct.new(:x, :y)

        PointD = SQL::Types.Definition(Point)

        PointTR = SQL::Types.Constructor(Point) do |p|
          x, y = p.to_s[1...-1].split(',', 2)
          Point.new(Float(x), Float(y))
        end

        PointT = SQL::Types.Constructor(Point) { |p| "(#{ p.x },#{ p.y })" }.meta(read: PointTR)

        Line = ::Struct.new(:a, :b, :c)

        LineTR = SQL::Types.Constructor(Line) do |ln|
          a, b, c = ln.to_s[1..-2].split(',', 3)
          Line.new(Float(a), Float(b), Float(c))
        end

        LineT = SQL::Types.Constructor(Line) { |ln| "{#{ ln.a },#{ ln.b },#{ln.c}}"}.meta(read: LineTR)

        Circle = ::Struct.new(:center, :radius)

        CircleTR = SQL::Types.Constructor(Circle) do |c|
          x, y, r = c.to_s.tr('()<>', '').split(',', 3)
          center = Point.new(Float(x), Float(y))
          Circle.new(center, Float(r))
        end

        CircleT = SQL::Types.Constructor(Circle) { |c|
          "<(#{ c.center.x },#{ c.center.y }),#{ c.radius }>"
        }.meta(read: CircleTR)

        Box = ::Struct.new(:upper_right, :lower_left)

        BoxTR = SQL::Types.Constructor(Box) do |b|
          x_right, y_right, x_left, y_left = b.to_s.tr('()', '').split(',', 4)
          upper_right = Point.new(Float(x_right), Float(y_right))
          lower_left = Point.new(Float(x_left), Float(y_left))
          Box.new(upper_right, lower_left)
        end

        BoxT = SQL::Types.Constructor(Box) { |b|
          "((#{ b.upper_right.x },#{ b.upper_right.y }),(#{ b.lower_left.x },#{ b.lower_left.y }))"
        }.meta(read: BoxTR)

        LineSegment = ::Struct.new(:begin, :end)

        LineSegmentTR = SQL::Types.Constructor(LineSegment) do |lseg|
          x_begin, y_begin, x_end, y_end = lseg.to_s.tr('()[]', '').split(',', 4)
          point_begin = Point.new(Float(x_begin), Float(y_begin))
          point_end = Point.new(Float(x_end), Float(y_end))
          LineSegment.new(point_begin, point_end)
        end

        LineSegmentT = SQL::Types.Constructor(LineSegment) do |lseg|
          "[(#{ lseg.begin.x },#{ lseg.begin.y }),(#{ lseg.end.x },#{ lseg.end.y })]"
        end.meta(read: LineSegmentTR)

        Polygon = SQL::Types::Strict::Array.member(PointD)

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

        PathD = SQL::Types.Definition(Path)

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
