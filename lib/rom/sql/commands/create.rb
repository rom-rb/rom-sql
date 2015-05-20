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
        include Transaction
        include ErrorWrapper

        # Set command to associate tuples with a parent tuple using provided keys
        #
        # @example
        #   class CreateTask < ROM::Commands::Create[:sql]
        #     relation :tasks
        #     associates :user, [:user_id, :id]
        #   end
        #
        #   create_user = rom.command(:user).create.with(name: 'Jane')
        #
        #   create_tasks = rom.command(:tasks).create
        #     .with [{ title: 'One' }, { title: 'Two' } ]
        #
        #   command = create_user >> create_tasks
        #   command.call
        #
        # @param [Symbol] name The name of associated table
        # @param [Hash] options The options
        # @option options [Array] :key The association keys
        #
        # @api public
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

        # Inserts provided tuples into the database table
        #
        # @api private
        def execute(tuples)
          insert_tuples = with_input_tuples(tuples) do |tuple|
            attributes = input[tuple]
            validator.call(attributes)
            attributes.to_h
          end

          insert(insert_tuples)
        end

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
