module ROM
  module SQL
    module Postgres
      class TypeBuilder < Schema::TypeBuilder
        defines :db_numeric_types, :db_type_mapping, :db_array_type_matcher

        db_numeric_types %w(
          smallint integer bigint
          decimal numeric real
          double\ precision serial bigserial
        ).to_set.freeze

        db_type_mapping(
          'uuid'  => Types::UUID,
          'money' => Types::Money,
          'bytea' => Types::Bytea,
          'json'  => Types::JSON,
          'jsonb' => Types::JSONB,
          'xml' => Types::XML,
          'inet' => Types::IPAddress,
          'cidr' => Types::IPAddress,
          'macaddr' => SQL::Types::String,
          'point' => Types::Point,
          'hstore' => Types::HStore,
          'line' => Types::Line,
          'circle' => Types::Circle,
          'box' => Types::Box,
          'lseg' => Types::LineSegment,
          'polygon' => Types::Polygon,
          'path' => Types::Path,
          'int4range' => Types::Int4Range,
          'int8range' => Types::Int8Range,
          'numrange' => Types::NumRange,
          'tsrange' => Types::TsRange,
          'tstzrange' => Types::TsTzRange,
          'daterange' => Types::DateRange
        ).freeze

        db_array_type_matcher '[]'.freeze

        def map_pk_type(type, db_type)
          if numeric?(type, db_type)
            type = self.class.numeric_pk_type
          else
            type = map_type(type, db_type)
          end

          type.meta(primary_key: true)
        end

        def map_type(ruby_type, db_type, enum_values: nil, **_)
          if db_type.end_with?(self.class.db_array_type_matcher)
            Types::Array(db_type[0...-2])
          elsif enum_values
            SQL::Types::String.enum(*enum_values)
          else
            map_db_type(db_type) || super
          end
        end

        def map_db_type(db_type)
          self.class.db_type_mapping[db_type] ||
            (db_type.start_with?('timestamp') ? SQL::Types::Time : nil)
        end

        def numeric?(ruby_type, db_type)
          self.class.db_numeric_types.include?(db_type) || ruby_type == :integer
        end
      end
    end

    Schema::TypeBuilder.register(:postgres, Postgres::TypeBuilder.new.freeze)
  end
end
