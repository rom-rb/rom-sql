require 'rom/commands/result'

module ROM
  module SQL
    module Commands
      # Adds transaction interface to commands
      #
      # @api private
      module Transaction
        ROM::SQL::Rollback = Class.new(Sequel::Rollback)

        # Start a transaction
        #
        # @param [Hash] options The options hash supported by Sequel
        #
        # @return [ROM::Commands::Result::Success,ROM::Commands::Result::Failure]
        #
        # @api public
        def transaction(options = {}, &block)
          result = relation.dataset.db.transaction(options, &block)

          if result
            ROM::Commands::Result::Success.new(result)
          else
            ROM::Commands::Result::Failure.new(result)
          end
        rescue ROM::CommandError => e
          ROM::Commands::Result::Failure.new(e)
        end
      end
    end
  end
end
