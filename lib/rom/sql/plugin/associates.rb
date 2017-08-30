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

        class AssociateOptions
          attr_reader :name, :assoc, :opts

          def initialize(name, relation, opts)
            @name = name
            @opts = { assoc: name, keys: opts[:key] }

            relation.associations.try(name) do |assoc|
              @assoc = assoc
              @opts.update(assoc: assoc, keys: assoc.join_keys(relation.__registry__))
            end

            @opts.update(parent: opts[:parent]) if opts[:parent]
          end

          def after?
            assoc.is_a?(Association::ManyToMany)
          end

          def ensure_valid(command)
            raise MissingJoinKeysError.new(command, name) unless opts[:keys]
          end

          def to_hash
            { associate: opts }
          end
        end

        # @api private
        def self.included(klass)
          klass.class_eval do
            extend ClassMethods
            include InstanceMethods
            defines :associations

            associations Hash.new

            option :associations, default: -> { self.class.associations }
            option :configured_associations, default: -> { EMPTY_ARRAY }
          end
          super
        end

        module ClassMethods
          # @see ROM::Command::ClassInterface.build
          #
          # @api public
          def build(relation, options = EMPTY_HASH)
            command = super

            configured_assocs = command.configured_associations

            associate_options = command.associations.map { |(name, opts)|
              next if configured_assocs.include?(name)
              AssociateOptions.new(name, relation, opts)
            }.compact

            associate_options.each { |opts| opts.ensure_valid(self) }

            before_hooks = associate_options.reject(&:after?).map(&:to_hash)
            after_hooks = associate_options.select(&:after?).map(&:to_hash)

            command.
              with_opts(configured_associations: configured_assocs + associate_options.map(&:name)).
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

        module InstanceMethods
          # Set fk on tuples from parent tuple
          #
          # @param [Array<Hash>, Hash] tuples The input tuple(s)
          # @param [Hash] parent The parent tuple with its pk already set
          #
          # @return [Array<Hash>]
          #
          # @api public
          def associate(tuples, curried_parent = nil, assoc:, keys:, parent: curried_parent)
            result_type = result

            output_tuples =
              case assoc
              when Symbol
                fk, pk = keys

                with_input_tuples(tuples).map { |tuple|
                  tuple.merge(fk => parent.fetch(pk))
                }
              when Association::ManyToMany
                result_type = tuples.is_a?(Array) ? :many : :one

                assoc.persist(__registry__, tuples, parent)

                pk, fk = assoc.parent_combine_keys(__registry__)

                case parent
                when Array
                  parent.map do |p|
                    tuples.map { |tuple| Hash(tuple).merge(fk => p[pk]) }
                  end.flatten(1)
                else
                  tuples.map { |tuple| Hash(tuple).update(fk => parent[pk]) }
                end
              when Association
                with_input_tuples(tuples).map { |tuple|
                  assoc.associate(__registry__, tuple, parent)
                }
              end

            result_type == :one ? output_tuples[0] : output_tuples
          end

          # @api public
          def with_association(name, opts = EMPTY_HASH)
            self.class.build(
              relation,
              **options,
              associations: associations.merge(name => opts)
            )
          end

          # @api private
          def __registry__
            relation.__registry__
          end
        end
      end
    end
  end
end
