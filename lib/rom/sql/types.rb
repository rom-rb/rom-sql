require 'rom/types'

module ROM
  module SQL
    module Types
      include ROM::Types

      def self.Constructor(*args, &block)
        ROM::Types.Constructor(*args, &block)
      end

      def self.Definition(*args, &block)
        ROM::Types.Definition(*args, &block)
      end

      Serial = Int.meta(primary_key: true)

      Blob = Constructor(Sequel::SQL::Blob, &Sequel::SQL::Blob.method(:new))

      Void = Nil
    end
  end
end
