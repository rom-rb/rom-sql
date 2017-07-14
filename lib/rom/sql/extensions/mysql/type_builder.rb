require 'rom/sql/schema/attributes_inferrer'

module ROM
  module SQL
    module MySQL
      class TypeBuilder < Schema::TypeBuilder
      end
    end

    Schema::TypeBuilder.register(:mysql, MySQL::TypeBuilder.new.freeze)
  end
end
