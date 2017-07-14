require 'dry-types'

module ROM
  module SQL
    module SQLite
      module Types
        Object = ::ROM::SQL::Types::Any
      end
    end

    module Types
      SQLite = ::ROM::SQL::SQLite::Types
    end
  end
end
