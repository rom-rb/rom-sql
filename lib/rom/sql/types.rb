require 'rom/types'

module ROM
  module SQL
    module Types
      include ROM::Types

      def self.Constructor(*args, &block)
        ROM::Types.Constructor(*args, &block)
      end

      Serial = Int.constrained(gt: 0).meta(primary_key: true)

      Blob = Constructor(Sequel::SQL::Blob, &Sequel::SQL::Blob.method(:new))
    end
  end
end
