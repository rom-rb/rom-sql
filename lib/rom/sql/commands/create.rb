require 'rom/sql/commands'
require 'rom/sql/commands/error_wrapper'
require 'rom/sql/commands/transaction'

module ROM
  module SQL
    module Commands
      # SQL create command
      #
      # @api public
      class Create < ROM::Commands::Create
        adapter :sql

        include Transaction
        include ErrorWrapper

        use :associates

        # Inserts provided tuples into the database table
        #
        # @api public
        def execute(tuples)
          insert_tuples = with_input_tuples(tuples) do |tuple|
            attributes = input[tuple]
            validator.call(attributes)
            attributes.to_h
          end

          insert(insert_tuples)
        end

        private

        # Executes insert statement and returns inserted tuples
        #
        # @api private
        def insert(tuples)
          pks = tuples.map { |tuple| relation.insert(tuple) }
          relation.where(relation.primary_key => pks)
        end

        # Yields tuples for insertion or return an enumerator
        #
        # @api private
        def with_input_tuples(tuples)
          input_tuples = Array([tuples]).flatten.map
          return input_tuples unless block_given?
          input_tuples.each { |tuple| yield(tuple) }
        end
      end
    end
  end
end
