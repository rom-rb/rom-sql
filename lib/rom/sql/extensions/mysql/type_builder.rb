# frozen_string_literal: true

require 'rom/sql/schema/attributes_inferrer'

module ROM
  module SQL
    module MySQL
      class TypeBuilder < Schema::TypeBuilder
        defines :db_type_mapping

        db_type_mapping(
          'tinytext' => Types::String,
          'text' => Types::String,
          'mediumtext' => Types::String,
          'longtext' => Types::String
        ).freeze

        def map_type(ruby_type, db_type, **_)
          map_db_type(db_type) || super
        end

        def map_db_type(db_type)
          self.class.db_type_mapping[db_type]
        end
      end
    end

    Schema::TypeBuilder.register(:mysql, MySQL::TypeBuilder.new.freeze)
  end
end
