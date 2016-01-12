require 'dry-data'
require 'sequel'

module ROM
  module SQL
    module Types
      module PG
        Sequel.extension(:pg_json)

        Array = Dry::Data::Type.new(
          Sequel.method(:pg_json), primitive: Sequel::Postgres::JSONArray
        )

        Hash = Dry::Data::Type.new(
          Sequel.method(:pg_json), primitive: Sequel::Postgres::JSONHash
        )

        JSON = Array | Hash
      end
    end
  end
end
