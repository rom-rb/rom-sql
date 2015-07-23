module ROM
  module SQL
    class Relation < ROM::Relation
      # Class DSL for SQL relations
      #
      # @api private
      module ClassMethods
        # Set up model and association ivars for descendant class
        #
        # @api private
        def inherited(klass)
          klass.class_eval do
            class << self
              attr_reader :model, :associations
            end
          end
          klass.instance_variable_set('@model', Class.new(Sequel::Model))
          klass.instance_variable_set('@associations', [])
          super
        end

        # Set up a one-to-many association
        #
        # @example
        #   class Users < ROM::Relation[:sql]
        #     one_to_many :tasks, key: :user_id
        #
        #     def with_tasks
        #       association_join(:tasks)
        #     end
        #   end
        #
        # @param [Symbol] name The name of the association
        # @param [Hash] options The options hash
        # @option options [Symbol] :key Name of the key to join on
        # @option options [Hash] :on Additional conditions for join
        # @option options [Hash] :conditions Additional conditions for WHERE
        #
        # @api public
        def one_to_many(name, options)
          associations << [__method__, name, { relation: name }.merge(options)]
        end

        # Set up a many-to-many association
        #
        # @example
        #   class Tasks < ROM::Relation[:sql]
        #     many_to_many :tags,
        #       join_table: :task_tags,
        #       left_key: :task_id,
        #       right_key: :tag_id,
        #
        #     def with_tags
        #       association_join(:tags)
        #     end
        #   end
        #
        # @param [Symbol] name The name of the association
        # @param [Hash] options The options hash
        # @option options [Symbol] :join_table Name of the join table
        # @option options [Hash] :left_key Name of the left join key
        # @option options [Hash] :right_key Name of the right join key
        # @option options [Hash] :on Additional conditions for join
        # @option options [Hash] :conditions Additional conditions for WHERE
        #
        # @api public
        def many_to_many(name, options = {})
          associations << [__method__, name, { relation: name }.merge(options)]
        end

        # Set up a many-to-one association
        #
        # @example
        #   class Tasks < ROM::Relation[:sql]
        #     many_to_one :users, key: :user_id
        #
        #     def with_users
        #       association_join(:users)
        #     end
        #   end
        #
        # @param [Symbol] name The name of the association
        # @param [Hash] options The options hash
        # @option options [Symbol] :join_table Name of the join table
        # @option options [Hash] :key Name of the join key
        # @option options [Hash] :on Additional conditions for join
        # @option options [Hash] :conditions Additional conditions for WHERE
        #
        # @api public
        def many_to_one(name, options = {})
          associations << [__method__, name, { relation: name }.merge(options)]
        end

        # Finalize the relation by setting up its associations (if any)
        #
        # @api private
        def finalize(relations, relation)
          return unless relation.dataset.db.table_exists?(dataset)

          model.set_dataset(relation.dataset)
          model.dataset.naked!

          associations.each do |*args, assoc_opts|
            options = Hash[assoc_opts]
            other = relations[options.delete(:relation) || args[1]].model
            model.public_send(*args, options.merge(class: other))
          end

          model.freeze

          super
        end
      end
    end
  end
end
