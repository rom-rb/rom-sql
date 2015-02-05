require 'rom/sql/commands'

module ROM
  module SQL
    module Commands
      class Delete < ROM::Commands::Delete
        def execute
          deleted = target.to_a
          target.delete
          deleted
        end
      end
    end
  end
end
