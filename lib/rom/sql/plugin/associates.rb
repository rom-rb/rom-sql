module ROM
  module SQL
    module Plugin
      # Make a command that automaticaly sets FK attribute on input tuples
      #
      # @api private
      module Associates
        # @api private
        def self.included(klass)
          klass.extend(ClassMethods)
          super
        end

        module InstanceMethods
          # Set fk on tuples from parent tuple
          #
          # @param [Array<Hash>, Hash] tuples The input tuple(s)
          # @param [Hash] parent The parent tuple with its pk already set
          #
          # @return [Array<Hash>,Hash]
          #
          # @overload SQL::Commands::Create#execute
          #
          # @api public
          def execute(tuples, parent)
            fk, pk = association[:key]

            input_tuples = with_input_tuples(tuples).map { |tuple|
              tuple.merge(fk => parent.fetch(pk))
            }

            super(input_tuples)
          end
        end

        module ClassMethods
          # @api private
          def inherited(klass)
            klass.defines :associations
            klass.associations []
            super
          end

          # Set command to associate tuples with a parent tuple using provided keys
          #
          # @example
          #   class CreateTask < ROM::Commands::Create[:sql]
          #     relation :tasks
          #     associates :user, key: [:user_id, :id]
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
          def associates(name, options)
            if associations.include?(name)
              raise(
                ArgumentError,
                "#{name} association is already defined for #{self.class}"
              )
            end

            option :association, reader: true, default: -> command { options }
            include InstanceMethods

            associations << name
          end
        end
      end
    end
  end
end
