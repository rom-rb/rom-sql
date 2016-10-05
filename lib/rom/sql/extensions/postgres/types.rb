require 'dry-types'
require 'sequel'

module ROM
  module SQL
    module Types
      module PG
        # UUID

        UUID = Types::Strict::String.constrained(format: Regexp.new('^([0-9a-f]{8})-([0-9a-f]{4})-([0-9a-f]{4})-([0-9a-f]{2})([0-9a-f]{2})-([0-9a-f]{12})$'))

        # Array

        Sequel.extension(:pg_array)
        Sequel.extension(:pg_array_ops)

        Array = Dry::Types::Definition
                .new(Sequel::Postgres::PGArray)
                .constructor(Sequel.method(:pg_array))

        # JSON

        Sequel.extension(:pg_json)
        Sequel.extension(:pg_json_ops)

        JSONArray = Dry::Types::Definition
                    .new(Sequel::Postgres::JSONArray)
                    .constructor(Sequel.method(:pg_json))

        JSONHash = Dry::Types::Definition
                   .new(Sequel::Postgres::JSONHash)
                   .constructor(Sequel.method(:pg_json))

        JSONOp = Dry::Types::Definition
                 .new(Sequel::Postgres::JSONOp)
                 .constructor(Sequel.method(:pg_json))

        JSON = JSONArray | JSONHash | JSONOp

        # JSONB

        JSONBArray = Dry::Types::Definition
                     .new(Sequel::Postgres::JSONBArray)
                     .constructor(Sequel.method(:pg_jsonb))

        JSONBHash = Dry::Types::Definition
                    .new(Sequel::Postgres::JSONBHash)
                    .constructor(Sequel.method(:pg_jsonb))

        JSONBOp = Dry::Types::Definition
                  .new(Sequel::Postgres::JSONBOp)
                  .constructor(Sequel.method(:pg_jsonb))

        JSONB = JSONBArray | JSONBHash | JSONBOp

        # MONEY

        Bytea = Dry::Types::Definition
                .new(Sequel::SQL::Blob)
                .constructor(Sequel::SQL::Blob.method(:new))

        Money = Types::Strict::Decimal
      end
    end
  end
end
