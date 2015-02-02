require 'rom/commands'

module ROM
  module SQL
    module Commands
      ERRORS = [
        Sequel::UniqueConstraintViolation,
        Sequel::NotNullConstraintViolation
      ].freeze

      module TupleCount
        def tuple_count
          target.count
        end
      end
    end
  end
end

require 'rom/sql/commands/create'
require 'rom/sql/commands/update'
require 'rom/sql/commands/delete'
require 'rom/sql/commands_ext/postgres'
