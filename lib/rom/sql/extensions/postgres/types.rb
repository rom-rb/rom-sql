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

        @array_types = ::Hash.new do |hash, type|
          name = "#{ type }[]"
          array_type = Array.constructor(-> (v) { Sequel.pg_array(v, type) }).
                         meta(type: name, db_type: name, database: 'postgres')
          Attribute::TypeExtensions.register(array_type) { include ArrayMethods }
          hash[type] = array_type
        end

        def self.Array(db_type)
          @array_types[db_type]
        end

        # @!parse
        #   class ROM::SQL::Attribute
        #     # @!method contain(other)
        #     #   Check whether the array includes another array
        #     #   Translates to the @> operator
        #     #
        #     #   @param [Array] other
        #     #
        #     #   @return [SQL::Attribute<Types::Bool>]
        #     #
        #     #   @api public
        #
        #     # @!method get(idx)
        #     #   Get element by index (PG uses 1-based indexing)
        #     #
        #     #   @param [Integer] idx
        #     #
        #     #   @return [SQL::Attribute]
        #     #
        #     #   @api public
        #
        #     # @!method any(value)
        #     #   Check whether the array includes a value
        #     #   Translates to the ANY operator
        #     #
        #     #   @param [Object] value
        #     #
        #     #   @return [SQL::Attribute<Types::Bool>]
        #     #
        #     #   @api public
        #
        #     # @!method contained_by(other)
        #     #   Check whether the array is contained by another array
        #     #   Translates to the <@ operator
        #     #
        #     #   @param [Array] other
        #     #
        #     #   @return [SQL::Attribute<Types::Bool>]
        #     #
        #     #   @api public
        #
        #     # @!method length
        #     #   Return array size
        #     #
        #     #   @return [SQL::Attribute<Types::Int>]
        #     #
        #     #   @api public
        #
        #     # @!method overlaps(other)
        #     #   Check whether the arrays have common values
        #     #   Translates to &&
        #     #
        #     #   @param [Array] other
        #     #
        #     #   @return [SQL::Attribute<Types::Bool>]
        #     #
        #     #   @api public
        #
        #     # @!method remove_value(value)
        #     #   Remove elements by value
        #     #
        #     #   @param [Object] value
        #     #
        #     #   @return [SQL::Attribute<Types::PG::Array>]
        #     #
        #     #   @api public
        #
        #     # @!method join(delimiter, null_repr)
        #     #   Convert the array to a string by joining
        #     #   values with a delimiter (empty stirng by default)
        #     #   and optional filler for NULL values
        #     #   Translates to an `array_to_string` call
        #     #
        #     #   @param [Object] delimiter
        #     #   @param [Object] null
        #     #
        #     #   @return [SQL::Attribute<Types::String>]
        #     #
        #     #   @api public
        #
        #     # @!method +(other)
        #     #   Concatenate two arrays
        #     #
        #     #   @param [Array] other
        #     #
        #     #   @return [SQL::Attribute<Types::PG::Array>]
        #     #
        #     #   @api public
        #   end
        module ArrayMethods
          def contain(type, expr, other)
            Attribute[Types::Bool].meta(sql_expr: expr.pg_array.contains(type[other]))
          end

          def get(type, expr, idx)
            Attribute[type].meta(sql_expr: expr.pg_array[idx])
          end

          def any(type, expr, value)
            Attribute[Types::Bool].meta(sql_expr: { value => expr.pg_array.any })
          end

          def contained_by(type, expr, other)
            Attribute[Types::Bool].meta(sql_expr: expr.pg_array.contained_by(type[other]))
          end

          def length(type, expr)
            Attribute[Types::Int].meta(sql_expr: expr.pg_array.length)
          end

          def overlaps(type, expr, other_array)
            Attribute[Types::Bool].meta(sql_expr: expr.pg_array.overlaps(type[other_array]))
          end

          def remove_value(type, expr, value)
            Attribute[type].meta(sql_expr: expr.pg_array.remove(value))
          end

          def join(type, expr, delimiter = '', null = nil)
            Attribute[Types::String].meta(sql_expr: expr.pg_array.join(delimiter, null))
          end

          def +(type, expr, other)
            Attribute[type].meta(sql_expr: expr.pg_array.concat(other))
          end
        end

        Attribute::TypeExtensions.register(Array.constructor -> {  }) do
          include ArrayMethods
        end

        # JSON

        JSONArray = Types.Constructor(Sequel::Postgres::JSONArray, &Sequel.method(:pg_json))

        JSONHash = Types.Constructor(Sequel::Postgres::JSONArray, &Sequel.method(:pg_json))

        JSONOp = Types.Constructor(Sequel::Postgres::JSONOp, &Sequel.method(:pg_json))

        JSON = (JSONArray | JSONHash | JSONOp).meta(database: 'postgres', db_type: 'jsonb')

        # JSONB

        JSONBArray = Types.Constructor(Sequel::Postgres::JSONBArray, &Sequel.method(:pg_jsonb))

        JSONBHash = Types.Constructor(Sequel::Postgres::JSONBHash, &Sequel.method(:pg_jsonb))

        JSONBOp = Types.Constructor(Sequel::Postgres::JSONBOp, &Sequel.method(:pg_jsonb))

        JSONB = (JSONBArray | JSONBHash | JSONBOp).meta(database: 'postgres', db_type: 'jsonb')

        # @!parse
        #   class ROM::SQL::Attribute
        #     # @!method contain(value)
        #     #   Check whether the JSON value includes a json value
        #     #   Translates to the @> operator
        #     #
        #     #   @example
        #     #     people.where { fields.contain(gender: 'Female') }
        #     #     people.where(people[:fields].contain([name: 'age']))
        #     #     people.select { fields.contain(gender: 'Female').as(:is_female) }
        #     #
        #     #   @param [Hash,Array,Object] value
        #     #
        #     #   @return [SQL::Attribute<Types::Bool>]
        #     #
        #     #   @api public
        #
        #     # @!method contained_by(value)
        #     #   Check whether the JSON value is contained by other value
        #     #   Translates to the <@ operator
        #     #
        #     #   @example
        #     #     people.where { custom_values.contained_by(age: 25, foo: 'bar') }
        #     #
        #     #   @param [Hash,Array] value
        #     #
        #     #   @return [SQL::Attribute<Types::Bool>]
        #     #
        #     #   @api public
        #
        #     # @!method get(*path)
        #     #   Extract the JSON value using at the specified path
        #     #   Translates to -> or #> depending on the number of arguments
        #     #
        #     #   @example
        #     #     people.select { data.get('age').as(:person_age) }
        #     #     people.select { fields.get(0).as(:first_field) }
        #     #     people.select { fields.get('0', 'value').as(:first_field_value) }
        #     #
        #     #   @param [Array<Integer>,Array<String>] path Path to extract
        #     #
        #     #   @return [SQL::Attribute<Types::PG::JSON>,SQL::Attribute<Types::PG::JSONB>]
        #     #
        #     #   @api public
        #
        #     # @!method get_text(*path)
        #     #   Extract the JSON value as text using at the specified path
        #     #   Translates to ->> or #>> depending on the number of arguments
        #     #
        #     #   @example
        #     #     people.select { data.get('age').as(:person_age) }
        #     #     people.select { fields.get(0).as(:first_field) }
        #     #     people.select { fields.get('0', 'value').as(:first_field_value) }
        #     #
        #     #   @param [Array<Integer>,Array<String>] path Path to extract
        #     #
        #     #   @return [SQL::Attribute<Types::String>]
        #     #
        #     #   @api public
        #
        #     # @!method has_key(key)
        #     #   Does the JSON value have the specified top-level key
        #     #   Translates to ?
        #     #
        #     #   @example
        #     #     people.where { data.has_key('age') }
        #     #
        #     #   @param [String] key
        #     #
        #     #   @return [SQL::Attribute<Types::Bool>]
        #     #
        #     #   @api public
        #
        #     # @!method has_any_key(*keys)
        #     #   Does the JSON value have any of the specified top-level keys
        #     #   Translates to ?|
        #     #
        #     #   @example
        #     #     people.where { data.has_any_key('age', 'height') }
        #     #
        #     #   @param [Array<String>] keys
        #     #
        #     #   @return [SQL::Attribute<Types::Bool>]
        #     #
        #     #   @api public
        #
        #     # @!method has_all_keys(*keys)
        #     #   Does the JSON value have all the specified top-level keys
        #     #   Translates to ?&
        #     #
        #     #   @example
        #     #     people.where { data.has_all_keys('age', 'height') }
        #     #
        #     #   @param [Array<String>] keys
        #     #
        #     #   @return [SQL::Attribute<Types::Bool>]
        #     #
        #     #   @api public
        #
        #     # @!method merge(value)
        #     #   Concatenate two JSON values
        #     #   Translates to ||
        #     #
        #     #   @example
        #     #     people.select { data.merge(fetched_at: Time.now).as(:data) }
        #     #     people.select { (fields + [name: 'height', value: 165]).as(:fields) }
        #     #
        #     #   @param [Hash,Array] value
        #     #
        #     #   @return [SQL::Attribute<Types::PG::JSONB>]
        #     #
        #     #   @api public
        #
        #     # @!method +(value)
        #     #   An alias for ROM::SQL::Attribute<JSONB>#merge
        #     #
        #     #   @api public
        #
        #     # @!method delete(*path)
        #     #   Deletes the specified value by key, index, or path
        #     #   Translates to - or #- depending on the number of arguments
        #     #
        #     #   @example
        #     #     people.select { data.delete('age').as(:data_without_age) }
        #     #     people.select { fields.delete(0).as(:fields_without_first) }
        #     #     people.select { fields.delete(-1).as(:fields_without_last) }
        #     #     people.select { data.delete('deeply', 'nested', 'value').as(:data) }
        #     #     people.select { fields.delete('0', 'name').as(:data) }
        #     #
        #     #   @param [Array<String>] path
        #     #
        #     #   @return [SQL::Attribute<Types::PG::JSONB>]
        #     #
        #     #   @api public
        #   end
        module JSONMethods
          def self.[](type, wrap)
            parent = self
            Module.new do
              include parent
              define_method(:json_type) { type }
              define_method(:wrap, wrap)
            end
          end

          def get(type, expr, *path)
            Attribute[json_type].meta(sql_expr: wrap(expr)[path_args(path)])
          end

          def get_text(type, expr, *path)
            Attribute[Types::String].meta(sql_expr: wrap(expr).get_text(path_args(path)))
          end

          private

          def path_args(path)
            case path.size
            when 0 then raise ArgumentError, "wrong number of arguments (given 0, expected 1+)"
            when 1 then path[0]
            else path
            end
          end
        end

        Attribute::TypeExtensions.register(JSON) do
          include JSONMethods[JSON, :pg_json.to_proc]
        end

        Attribute::TypeExtensions.register(JSONB) do
          include JSONMethods[JSONB, :pg_jsonb.to_proc]

          def contain(type, expr, value)
            Attribute[Types::Bool].meta(sql_expr: wrap(expr).contains(value))
          end

          def contained_by(type, expr, value)
            Attribute[Types::Bool].meta(sql_expr: wrap(expr).contained_by(value))
          end

          def has_key(type, expr, key)
            Attribute[Types::Bool].meta(sql_expr: wrap(expr).has_key?(key))
          end

          def has_any_key(type, expr, *keys)
            Attribute[Types::Bool].meta(sql_expr: wrap(expr).contain_any(keys))
          end

          def has_all_keys(type, expr, *keys)
            Attribute[Types::Bool].meta(sql_expr: wrap(expr).contain_all(keys))
          end

          def merge(type, expr, value)
            Attribute[JSONB].meta(sql_expr: wrap(expr).concat(value))
          end
          alias_method :+, :merge

          def delete(type, expr, *path)
            sql_expr = path.size == 1 ? wrap(expr) - path : wrap(expr).delete_path(path)
            Attribute[JSONB].meta(sql_expr: sql_expr)
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
