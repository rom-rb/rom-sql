require 'sequel'

require 'rom/sql/type_extensions'
require 'rom/sql/extensions/postgres/types/array'
require 'rom/sql/extensions/postgres/types/json'
require 'rom/sql/extensions/postgres/types/geometric'
require 'rom/sql/extensions/postgres/types/network'

Sequel.extension(:pg_hstore)

module ROM
  module SQL
    module Postgres
      module Types
        UUID = SQL::Types::String

        HStoreR = SQL::Types.Constructor(Hash, &:to_hash)
        HStore = SQL::Types.Constructor(Hash, &Sequel.method(:hstore))
                   .meta(read: HStoreR)

        Bytea = SQL::Types.Constructor(String, &Sequel::SQL::Blob.method(:new))

        Money = SQL::Types::Decimal
      end
    end

    module Types
      PG = Postgres::Types
    end
  end
end
