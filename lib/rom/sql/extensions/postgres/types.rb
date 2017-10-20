require 'sequel/core'

require 'rom/sql/type_extensions'

Sequel.extension(:pg_hstore)

module ROM
  module SQL
    module Postgres
      module Types
        def self.Type(name, type = yield)
          type.meta(db_type: name, database: 'postgres')
        end

        UUID = Type('uuid', SQL::Types::String)

        HStore = Type('hstore') do
          read = SQL::Types.Constructor(Hash, &:to_hash)

          SQL::Types.Constructor(Hash, &Sequel.method(:hstore))
            .meta(read: read)
        end

        Bytea = Type('bytea') do
          SQL::Types.Constructor(Sequel::SQL::Blob, &Sequel::SQL::Blob.method(:new))
        end

        Money = Type('money', SQL::Types::Decimal)

        XML = Type('xml', SQL::Types::String)
      end
    end

    module Types
      PG = Postgres::Types
    end
  end
end

require 'rom/sql/extensions/postgres/types/array'
require 'rom/sql/extensions/postgres/types/json'
require 'rom/sql/extensions/postgres/types/geometric'
require 'rom/sql/extensions/postgres/types/network'
require 'rom/sql/extensions/postgres/types/range'
