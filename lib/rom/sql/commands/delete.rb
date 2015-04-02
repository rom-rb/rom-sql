require 'rom/sql/commands'
require 'rom/sql/commands/error_wrapper'
require 'rom/sql/commands/transaction'

module ROM
  module SQL
    module Commands
      class Delete < ROM::Commands::Delete
        include Transaction
        prepend ErrorWrapper

        def execute
          deleted = target.to_a
          target.delete
          deleted
        end
      end
    end
  end
end
