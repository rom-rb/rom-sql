require 'rom/sql/schema/inferrer'
require 'rom/sql/extensions/postgres/types'

module ROM
  module SQL
    class Schema
      class PostgresInferrer < Inferrer[:postgres]
        type_mapping(
          **superclass.type_mapping,
          json: ROM::SQL::Types::PG::JSON
        )
      end
    end
  end
end
