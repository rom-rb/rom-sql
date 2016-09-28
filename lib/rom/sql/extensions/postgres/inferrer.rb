require 'rom/sql/schema/inferrer'

module ROM
  module SQL
    class Schema
      class PostgresInferrer < Inferrer[:postgres]
      end
    end
  end
end
