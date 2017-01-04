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
          attr_reader :assoc, :__registry__

          # @api private
          def initialize(*)
            super
            @__registry__ = relation.__registry__
            assoc_name, assoc_opts = self.class.associations[0]
            @assoc =
              if assoc_opts.any?
                assoc_opts[:key]
              else
                relation.associations[assoc_name]
              end
          end

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
            input_tuples =
              case assoc
              when Array
                fk, pk = assoc

                input_tuples = with_input_tuples(tuples).map { |tuple|
                  tuple.merge(fk => parent.fetch(pk))
                }

                super(input_tuples)
              when Association::ManyToMany
                new_tuples = super(tuples)

                join_tuples = assoc.associate(__registry__, new_tuples, parent)
                join_relation = assoc.join_relation(__registry__)
                join_relation.multi_insert(join_tuples)

                pk, fk = __registry__[assoc.target]
                  .associations[assoc.source]
                  .combine_keys(__registry__).to_a.flatten

                pk_extend = { fk => parent[pk] }

                new_tuples.map { |tuple| tuple.update(pk_extend) }
              when Association
                input_tuples = with_input_tuples(tuples).map { |tuple|
                  assoc.associate(relation.__registry__, tuple, parent)
                }
                super(input_tuples)
              end
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
          def associates(name, options = {})
            if associations.map(&:first).include?(name)
              raise ArgumentError,
                "#{name} association is already defined for #{self.class}"
            end

            option :association, reader: true, default: proc { Hash.new }

            include InstanceMethods

            associations << [name, options]
          end
        end
      end
    end
  end
end
