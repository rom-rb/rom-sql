require 'rom/sql/types/pg'

module ROM
  module SQL
    class Schema < ROM::Schema
      class ColumnInferrer
        extend ClassMacros

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

        # @api private
        def infer(name, primary_key:, type:, db_type:, allow_null:, foreign_key:, **rest)
          result = infer_column_type(name, primary_key, type, db_type)
          result = result.optional                                       if allow_null
          result = result.meta(primary_key: true)                        if primary_key
          result = result.meta(foreign_key: true, relation: foreign_key) if foreign_key
          result
        end

        protected

        def infer_column_type(name, primary_key, type, db_type)
          infer_numeric_pk(primary_key, type, db_type) ||
            infer_db_type(name, db_type) ||
            infer_ruby_type(type)
        end

        def infer_numeric_pk(primary_key, type, db_type)
          Types::Serial if primary_key && numeric?(type, db_type)
        end

        def infer_db_type(name, db_type)
          self.class.db_type_mapping.fetch(db_type) do
            Types::PG::Array if db_type.end_with?(self.class.db_array_type_matcher)
          end
        end

        def infer_ruby_type(type)
          self.class.ruby_type_mapping.fetch(type)
        end

        def numeric?(type, db_type)
          self.class.db_numeric_types.fetch(db_type) do
            type == :integer
          end
        end
      end
    end
  end
end
