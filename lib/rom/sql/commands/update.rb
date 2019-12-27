# frozen_string_literal: true

require 'rom/sql/commands/error_wrapper'

module ROM
  module SQL
    module Commands
      # Update command
      #
      # @api public
      class Update < ROM::Commands::Update
        adapter :sql

        include ErrorWrapper

        use :schema
        use :associates

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

        # Yields tuples for insertion or return an enumerator
        #
        # @api private
        def with_input_tuples(tuples)
          input_tuples = Array([tuples]).flatten(1).map
          return input_tuples unless block_given?
          input_tuples.each { |tuple| yield(tuple) }
        end
      end
    end
  end
end
