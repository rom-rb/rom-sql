require 'rom/types'

module ROM
  module SQL
    module Types
      include ROM::Types

      singleton_class.send(:define_method, :Constructor, &ROM::Types.method(:Constructor))

      Serial = Int.constrained(gt: 0).meta(primary_key: true)

      Blob = Constructor(Sequel::SQL::Blob, &Sequel::SQL::Blob.method(:new))
    end
  end
end
