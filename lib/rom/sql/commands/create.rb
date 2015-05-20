require 'rom/sql/commands'
require 'rom/sql/commands/error_wrapper'
require 'rom/sql/commands/transaction'

module ROM
  module SQL
    module Commands
      class Create < ROM::Commands::Create
        include Transaction
        include ErrorWrapper

        def self.associates(name, options)
          option :association, reader: true, default: -> command { options }

          define_method(:execute) do |tuples, parent|
            fk, pk = association[:key]

            input_tuples = with_input_tuples(tuples).map { |tuple|
              tuple.merge(fk => parent.fetch(pk))
            }

            super(input_tuples)
          end
        end

        def execute(tuples)
          insert_tuples = with_input_tuples(tuples) do |tuple|
            attributes = input[tuple]
            validator.call(attributes)
            attributes.to_h
          end

          insert(insert_tuples)
        end

        def insert(tuples)
          pks = tuples.map { |tuple| relation.insert(tuple) }
          relation.where(relation.primary_key => pks)
        end

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
