module ROM
  module SQL
    module Plugin
      # Make a command that automaticaly sets FK attribute on input tuples
      #
      # @api private
      module Associates
        class MissingJoinKeysError < StandardError
          ERROR_TEMPLATE = ':%{command} command for :%{relation} relation ' \
                           'is missing join keys configuration for :%{name} association'

          def initialize(command, assoc_name)
            super(ERROR_TEMPLATE % tokens(command, assoc_name))
          end

          def tokens(command, assoc_name)
            { command: command.register_as,
              relation: command.relation,
              name: assoc_name }
          end
        end

        # @api private
        def self.included(klass)
          klass.class_eval do
            extend ClassMethods
            include InstanceMethods
            defines :associations

            associations Hash.new

            option :associations, reader: true, optional: true, default: -> cmd { cmd.class.associations }
            option :configured_associations, reader: true, optional: true, default: proc { [] }
          end
          super
        end

        module InstanceMethods
          # Set fk on tuples from parent tuple
          #
          # @param [Array<Hash>, Hash] tuples The input tuple(s)
          # @param [Hash] parent The parent tuple with its pk already set
          #
          # @return [Array<Hash>]
          #
          # @api public
          def associate(tuples, parent, assoc:, keys:)
            input_tuples =
              case assoc
              when Symbol
                fk, pk = keys

                with_input_tuples(tuples).map { |tuple|
                  tuple.merge(fk => parent.fetch(pk))
                }
              when Association::ManyToMany
                join_tuples = assoc.associate(__registry__, tuples, parent)
                join_relation = assoc.join_relation(__registry__)
                join_relation.multi_insert(join_tuples)

                pk, fk = __registry__[assoc.target]
                  .associations[assoc.source]
                  .combine_keys(__registry__).to_a.flatten

                pk_extend = { fk => parent[pk] }

                tuples.map { |tuple| tuple.update(pk_extend) }
              when Association
                with_input_tuples(tuples).map { |tuple|
                  assoc.associate(relation.__registry__, tuple, parent)
                }
              end

            one? ? input_tuples[0] : input_tuples
          end

          # @api public
          def with_association(name, opts = EMPTY_HASH)
            self.class.build(
              relation, options.merge(associations: associations.merge(name => opts))
            )
          end

          def associations_configured?
            if configured_associations.empty?
              false
            else
              configured_associations.all? { |name| associations.key?(name) }
            end
          end

          # @api private
          def __registry__
            relation.__registry__
          end
        end

        module ClassMethods
          # @see ROM::Command::ClassInterface.build
          #
          # @api public
          def build(relation, options = EMPTY_HASH)
            command = super

            if command.associations_configured?
              return command
            end

            associations = command.associations
            assoc_names = []

            before_hooks = associations.each_with_object([]) do |(name, opts), acc|
              relation.associations.try(name) do |assoc|
                unless assoc.is_a?(Association::ManyToMany)
                  acc << { associate: { assoc: assoc, keys: assoc.join_keys(relation.__registry__) } }
                else
                  true
                end
              end or acc << { associate: { assoc: name, keys: opts[:key] } }

              assoc_names << name
            end

            after_hooks = associations.each_with_object([]) do |(name, opts), acc|
              next unless relation.associations.key?(name)

              assoc = relation.associations[name]

              if assoc.is_a?(Association::ManyToMany)
                acc << { associate: { assoc: assoc, keys: assoc.join_keys(relation.__registry__) } }
                assoc_names << name
              end
            end

            [*before_hooks, *after_hooks].
              map { |hook| hook[:associate] }.
              each { |conf| raise MissingJoinKeysError.new(self, conf[:assoc]) unless conf[:keys] }

            command.
              with_opts(configured_associations: assoc_names).
              before(*before_hooks).
              after(*after_hooks)
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
          def associates(name, options = EMPTY_HASH)
            if associations.key?(name)
              raise ArgumentError,
                    "#{name} association is already defined for #{self.class}"
            end

            associations(associations.merge(name => options))
          end
        end
      end
    end
  end
end
