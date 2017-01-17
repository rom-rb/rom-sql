require 'rom/sql/schema/inferrer'

module ROM
  module SQL
    class Schema
      class MysqlInferrer < Inferrer[:mysql]
      end
    end
  end
end
