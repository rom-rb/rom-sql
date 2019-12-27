# frozen_string_literal: true

require 'dry-types'

module ROM
  module SQL
    module SQLite
      module Types
        Any = ::ROM::SQL::Types::Any
        Object = Any
      end
    end

    module Types
      SQLite = ::ROM::SQL::SQLite::Types
    end
  end
end
