require 'rom/types'

module ROM
  module SQL
    module Types
      include ROM::Types

      Serial = Int.constrained(gt: 0).meta(primary_key: true)
      Bool   = ROM::Types::Bool.optional

      Blob = Dry::Types::Definition
        .new(Sequel::SQL::Blob)
        .constructor(Sequel::SQL::Blob.method(:new))
    end
  end
end
