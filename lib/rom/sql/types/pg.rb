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
      end
    end
  end
end
