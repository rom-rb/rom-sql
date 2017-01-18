require 'rom/sql/schema/inferrer'

module ROM
  module SQL
    class Schema
      class SqliteInferrer < Inferrer[:sqlite]
      end
    end
  end
end
