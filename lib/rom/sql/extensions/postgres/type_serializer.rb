module ROM
  module SQL
    module Postgres
      # @api private
      class TypeSerializer < ROM::SQL::TypeSerializer
        mapping(
          mapping.merge(
            SQL::Types::String => 'text'
          )
        )
      end
    end

    TypeSerializer.register(:postgres, Postgres::TypeSerializer.new.freeze)
  end
end
