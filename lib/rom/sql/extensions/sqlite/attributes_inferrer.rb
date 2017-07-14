require 'rom/sql/schema/attributes_inferrer'

module ROM
  module SQL
    module SQLite
      class AttributesInferrer < Schema::AttributesInferrer[:sqlite]
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
