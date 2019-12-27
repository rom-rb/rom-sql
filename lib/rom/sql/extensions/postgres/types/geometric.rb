# frozen_string_literal: true

module ROM
  module SQL
    module Postgres
      module Values
        Point = ::Struct.new(:x, :y)

        Line = ::Struct.new(:a, :b, :c)

        Circle = ::Struct.new(:center, :radius)

        Box = ::Struct.new(:upper_right, :lower_left)

        LineSegment = ::Struct.new(:begin, :end)

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
      end

      # @api public
      module Types
        # The list of geometric data types supported by PostgreSQL
        # @see https://www.postgresql.org/docs/current/static/datatype-geometric.html

        Point = Type('point') do
          SQL::Types.define(Values::Point) do
            input do |point|
              "(#{ point.x },#{ point.y })"
            end

            output do |point|
              x, y = point.to_s[1...-1].split(',', 2)
              Values::Point.new(Float(x), Float(y))
            end
          end
        end

        Line = Type('line') do
          SQL::Types.define(Values::Line) do
            input do |line|
              "{#{ line.a },#{ line.b },#{line.c}}"
            end

            output do |line|
              a, b, c = line.to_s[1..-2].split(',', 3)
              Values::Line.new(Float(a), Float(b), Float(c))
            end
          end
        end

        Circle = Type('circle') do
          SQL::Types.define(Values::Circle) do
            input do |circle|
              "<(#{ circle.center.x },#{ circle.center.y }),#{ circle.radius }>"
            end

            output do |circle|
              x, y, r = circle.to_s.tr('()<>', '').split(',', 3)
              center = Values::Point.new(Float(x), Float(y))
              Values::Circle.new(center, Float(r))
            end
          end
        end

        Box = Type('box') do
          SQL::Types.define(Values::Box) do
            input do |box|
              "((#{ box.upper_right.x },#{ box.upper_right.y }),"\
              "(#{ box.lower_left.x },#{ box.lower_left.y }))"
            end

            output do |box|
              x_right, y_right, x_left, y_left = box.to_s.tr('()', '').split(',', 4)
              upper_right = Values::Point.new(Float(x_right), Float(y_right))
              lower_left = Values::Point.new(Float(x_left), Float(y_left))
              Values::Box.new(upper_right, lower_left)
            end
          end
        end

        LineSegment = Type('lseg') do
          SQL::Types.define(Values::LineSegment) do
            input do |segment|
              "[(#{ segment.begin.x },#{ segment.begin.y }),"\
              "(#{ segment.end.x },#{ segment.end.y })]"
            end

            output do |segment|
              x_begin, y_begin, x_end, y_end = segment.to_s.tr('()[]', '').split(',', 4)
              point_begin = Values::Point.new(Float(x_begin), Float(y_begin))
              point_end = Values::Point.new(Float(x_end), Float(y_end))
              Values::LineSegment.new(point_begin, point_end)
            end
          end
        end

        Polygon = Type('polygon') do
          SQL::Types.define(::Array) do
            input do |points|
              points_joined = points.map { |p| "(#{ p.x },#{ p.y })" }.join(',')
              "(#{ points_joined })"
            end

            output do |polygon|
              coordinates = polygon.to_s.tr('()', '').split(',').each_slice(2)
              coordinates.map { |x, y| Values::Point.new(Float(x), Float(y)) }
            end
          end
        end

        Path = Type('path') do
          SQL::Types.define(Values::Path) do
            input do |path|
              points_joined = path.to_a.map { |p| "(#{ p.x },#{ p.y })" }.join(',')

              if path.open?
                "[#{ points_joined }]"
              else
                "(#{ points_joined })"
              end
            end

            output do |path|
              open = path.to_s.start_with?('[') && path.to_s.end_with?(']')
              coordinates = path.to_s.tr('()[]', '').split(',').each_slice(2)
              points = coordinates.map { |x, y| Values::Point.new(Float(x), Float(y)) }

              if open
                Values::Path.new(points, :open)
              else
                Values::Path.new(points, :closed)
              end
            end
          end
        end
      end
    end
  end
end
