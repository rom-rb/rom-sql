require 'rom/commands/result'

module ROM
  module SQL
    module Commands
      module Transaction
        ROM::SQL::Rollback = Class.new(Sequel::Rollback)

        def transaction(options = {}, &block)
          result = relation.dataset.db.transaction(options, &block)

          if result
            ROM::Commands::Result::Success.new(result)
          else
            ROM::Commands::Result::Failure.new(result)
          end
        rescue => e
          ROM::Commands::Result::Failure.new(e)
        end
      end
    end
  end
end
