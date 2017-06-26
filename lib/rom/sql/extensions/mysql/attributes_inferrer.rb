require 'rom/sql/schema/attributes_inferrer'

module ROM
  module SQL
    class Schema
      class MysqlInferrer < AttributesInferrer[:mysql]
      end
    end
  end
end
