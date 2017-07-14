require 'rom/sql/schema/attributes_inferrer'

module ROM
  module SQL
    module MySQL
      class AttributesInferrer < Schema::AttributesInferrer[:mysql]
      end
    end
  end
end
