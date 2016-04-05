require 'rom/sql/commands/error_wrapper'
require 'rom/sql/commands/transaction'

module ROM
  module SQL
    module Commands
      # SQL delete command
      #
      # @api public
      class Delete < ROM::Commands::Delete
        adapter :sql

        include Transaction
        include ErrorWrapper

        # Deletes tuples from a relation
        #
        # @return [Array<Hash>] deleted tuples
        #
        # @api public
        def execute
          deleted = relation.to_a
          relation.delete
          deleted
        end
      end
    end
  end
end
