require 'rom/sql/commands/error_wrapper'
require 'rom/sql/commands/transaction'

module ROM
  module SQL
    module Commands
      # Update command
      #
      # @api public
      class Update < ROM::Commands::Update
        adapter :sql

        include Transaction
        include ErrorWrapper

        use :schema

        after :finalize

        # Updates existing tuple in a relation
        #
        # @return [Array<Hash>, Hash]
        #
        # @api public
        def execute(tuple)
          update(input[tuple].to_h)
        end

        private

        # @api private
        def finalize(tuples, *)
          tuples.map { |t| relation.output_schema[t] }
        end

        # Executes update statement for a given tuple
        #
        # @api private
        def update(tuple)
          pks = relation.map { |t| t[primary_key] }
          dataset = relation.dataset
          dataset.update(tuple)
          dataset.unfiltered.where(primary_key => pks).to_a
        end

        # @api private
        def primary_key
          relation.primary_key
        end
      end
    end
  end
end
