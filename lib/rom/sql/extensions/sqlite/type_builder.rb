# frozen_string_literal: true

module ROM
  module SQL
    module SQLite
      class TypeBuilder < Schema::TypeBuilder
        NO_TYPE = EMPTY_STRING

        # @api private
        def map_type(_, db_type, **_kw)
          if db_type.eql?(NO_TYPE)
            ROM::SQL::Types::SQLite::Any
          else
            super
          end
        end
      end
    end

    Schema::TypeBuilder.register(:sqlite, SQLite::TypeBuilder.new.freeze)
  end
end
