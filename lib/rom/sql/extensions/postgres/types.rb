require 'dry-types'
require 'sequel'

module ROM
  module SQL
    module Types
      module PG
        Sequel.extension(:pg_json)

        Array = Dry::Types::Definition
                .new(Sequel::Postgres::JSONArray)
                .constructor(Sequel.method(:pg_json))

        Hash = Dry::Types::Definition
               .new(Sequel::Postgres::JSONHash)
               .constructor(Sequel.method(:pg_json))

        JSON = Array | Hash

        Bytea = Dry::Types::Definition
                .new(Sequel::SQL::Blob)
                .constructor(Sequel::SQL::Blob.method(:new))
      end
    end
  end
end
