require 'rom/sql/schema/inferrer'
require 'rom/sql/extensions/postgres/types'

module ROM
  module SQL
    class Schema
      class PostgresInferrer < Inferrer[:postgres]
        defines :db_numeric_types, :db_type_mapping, :ruby_type_mapping, :db_array_type_matcher

        db_numeric_types(
          'smallint'         => true,
          'integer'          => true,
          'bigint'           => true,
          'decimal'          => true,
          'numeric'          => true,
          'real'             => true,
          'double precision' => true,
          'serial'           => true,
          'bigserial'        => true,
        ).freeze

        db_type_mapping(
          'uuid'  => Types::PG::UUID,
          'money' => Types::PG::Money,
          'bytea' => Types::Blob,
          'json'  => Types::PG::JSON,
          'jsonb' => Types::PG::JSONB,
        ).freeze

        ruby_type_mapping(
          integer: Types::Strict::Int,
          string: Types::Strict::String,
          date: Types::Strict::Date,
          datetime: Types::Strict::Time,
          boolean: Types::Strict::Bool,
          decimal: Types::Strict::Decimal,
          blob: Types::Strict::String
        ).freeze

        db_array_type_matcher ']'.freeze

        private

        def map_pk_type(type, db_type)
          if numeric?(type, db_type)
            self.class.numeric_pk_type.meta(primary_key: true)
          end
        end

        def map_type(ruby_type, db_type)
          if db_type.end_with?(self.class.db_array_type_matcher)
            Types::PG::Array
          else
            map_db_type(db_type) || map_ruby_type(ruby_type) ||
              raise(UnknownDBTypeError, "Cannot find corresponding type for #{ruby_type || db_type}")
          end
        end

        def map_db_type(db_type)
          self.class.db_type_mapping[db_type]
        end

        def map_ruby_type(ruby_type)
          self.class.ruby_type_mapping[ruby_type]
        end

        def numeric?(ruby_type, db_type)
          self.class.db_numeric_types.fetch(db_type) do
            ruby_type == :integer
          end
        end
      end
    end
  end
end
