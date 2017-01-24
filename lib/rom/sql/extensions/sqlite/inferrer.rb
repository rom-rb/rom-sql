require 'rom/sql/schema/inferrer'

module ROM
  module SQL
    class Schema
      class SqliteInferrer < Inferrer[:sqlite]
        NO_TYPE = EMPTY_STRING

        def map_type(_, db_type, **_kw)
          if db_type.eql?(NO_TYPE)
            ROM::SQL::Types::SQLite::Object
          else
            super
          end
        end
      end
    end
  end
end
