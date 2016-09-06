require 'rom/types'

module ROM
  module SQL
    module Types
      include ROM::Types

      Serial = Strict::Int.constrained(gt: 0).meta(primary_key: true)

      Blob = Dry::Types::Definition
        .new(Sequel::SQL::Blob)
        .constructor(Sequel::SQL::Blob.method(:new))
    end
  end
end
