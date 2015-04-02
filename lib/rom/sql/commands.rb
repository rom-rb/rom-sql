require 'rom/commands'

module ROM
  module SQL
    module Commands
      ERRORS = [
        Sequel::UniqueConstraintViolation,
        Sequel::NotNullConstraintViolation,
        Sequel::DatabaseError
      ].freeze
    end
  end
end

require 'rom/sql/commands/create'
require 'rom/sql/commands/update'
require 'rom/sql/commands/delete'
require 'rom/sql/commands_ext/postgres'
