require 'rom/commands/result'

module ROM
  module SQL
    module Commands
      module Transaction
        ROM::SQL::Rollback = Class.new(Sequel::Rollback)

        def transaction(options = {}, &block)
          ROM::Commands::Result::Success.new(
            relation.dataset.db.transaction(options, &block)
          )
        end
      end
    end
  end
end
