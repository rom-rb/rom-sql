# frozen_string_literal: true

require 'rom/sql/associations'

module ROM
  module SQL
    module Plugin
      # Make a command that automaticaly sets FK attribute on input tuples
      #
      # @api private
      module Associates
        class AssociateOptions
          attr_reader :name, :assoc, :opts

          # @api private
          def initialize(name, relation, opts)
            @name = name
            @assoc = relation.associations[name]
            @opts = { assoc: assoc, keys: assoc.join_keys }
            @opts.update(parent: opts[:parent]) if opts[:parent]
          end

          def after?
            assoc.is_a?(SQL::Associations::ManyToMany)
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

        # @api public
        module ClassMethods
          # @see ROM::Command::ClassInterface.build
          #
          # @api public
          def build(relation, **options)
            command = super

            configured_assocs = command.configured_associations

            associate_options = command.associations.map { |(name, opts)|
              next if configured_assocs.include?(name)
              AssociateOptions.new(name, relation, opts)
            }.compact

            before_hooks = associate_options.reject(&:after?).map(&:to_hash)
            after_hooks = associate_options.select(&:after?).map(&:to_hash)

            command.
              with(configured_associations: configured_assocs + associate_options.map(&:name)).
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
          #   create_user = rom.command(:user).create.curry(name: 'Jane')
          #
          #   create_tasks = rom.command(:tasks).create
          #     .curry [{ title: 'One' }, { title: 'Two' } ]
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
              when SQL::Associations::ManyToMany
                result_type = tuples.is_a?(Array) ? :many : :one

                assoc.persist(tuples, parent)

                pk, fk = assoc.parent_combine_keys

                case parent
                when Array
                  parent.flat_map do |p|
                    tuples.map { |tuple| Hash(tuple).merge(fk => p[pk]) }
                  end
                else
                  tuples.map { |tuple| Hash(tuple).update(fk => parent[pk]) }
                end
              else
                with_input_tuples(tuples).map { |tuple|
                  assoc.associate(tuple, parent)
                }
              end

            result_type == :one ? output_tuples[0] : output_tuples
          end

          # Return a new command with the provided association
          #
          # @param [Symbol, Relation::Name] name The name of the association
          #
          # @return [Command]
          #
          # @api public
          def with_association(name, opts = EMPTY_HASH)
            self.class.build(
              relation,
              **options, associations: associations.merge(name => opts)
            )
          end
        end
      end
    end
  end
end
