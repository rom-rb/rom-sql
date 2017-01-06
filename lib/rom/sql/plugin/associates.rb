module ROM
  module SQL
    module Plugin
      # Make a command that automaticaly sets FK attribute on input tuples
      #
      # @api private
      module Associates
        # @api private
        def self.included(klass)
          klass.class_eval do
            extend ClassMethods
            include InstanceMethods
            defines :associations

            associations []

            option :associations, reader: true, optional: true, default: -> cmd { cmd.class.associations }
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
          end

          # @api public
          def with_association(name, opts = EMPTY_HASH)
            self.class.build(relation, options.merge(associations: [[name, opts]]))
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
            associations = command.associations

            before_hooks = associations.each_with_object([]) do |(name, opts), acc|
              relation.associations.try(name) do |assoc|
                unless assoc.is_a?(Association::ManyToMany)
                  acc << { associate: { assoc: assoc, keys: assoc.join_keys(relation.__registry__) } }
                else
                  true
                end
              end or acc << { associate: { assoc: name, keys: opts[:key] } }
            end

            after_hooks = associations.each_with_object([]) do |(name, opts), acc|
              next unless relation.associations.key?(name)

              assoc = relation.associations[name]

              if assoc.is_a?(Association::ManyToMany)
                acc << { associate: { assoc: assoc, keys: assoc.join_keys(relation.__registry__) } }
              end
            end

            command.before(*before_hooks).after(*after_hooks)
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
            if associations.map(&:first).include?(name)
              raise ArgumentError,
                    "#{name} association is already defined for #{self.class}"
            end

            associations(associations.dup << [name, options])
          end
        end
      end
    end
  end
end
