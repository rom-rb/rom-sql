module ROM
  module SQL

    # Sequel-specific relation extensions
    #
    module RelationInclusion

      def self.included(klass)
        klass.extend(AssociationDSL)

        klass.send(:undef_method, :select)

        klass.class_eval {
          class << self
            attr_accessor :model
          end

          self.model = Class.new(Sequel::Model)
        }
      end

      def initialize(*args)
        super
        @model = self.class.model
        @header = dataset.header
      end

      # Join configured association.
      #
      # Uses INNER JOIN type.
      #
      # @example
      #
      #   setup.relation(:tasks)
      #
      #   setup.relations(:users) do
      #     one_to_many :tasks, key: :user_id
      #
      #     def with_tasks
      #       association_join(:tasks, select: [:title])
      #     end
      #   end
      #
      # @api public
      def association_join(*args)
        send(:append_association, __method__, *args)
      end

      # Join configured association
      #
      # Uses LEFT JOIN type.
      #
      # @example
      #
      #   setup.relation(:tasks)
      #
      #   setup.relations(:users) do
      #     one_to_many :tasks, key: :user_id
      #
      #     def with_tasks
      #       association_left_join(:tasks, select: [:title])
      #     end
      #   end
      #
      # @api public
      def association_left_join(*args)
        send(:append_association, __method__, *args)
      end

      private

      # @api private
      def append_association(type, name, options = {})
        self.class.new(
          dataset.public_send(type, name).
          select_append(*columns_for_association(name, options))
        )
      end

      # @api private
      def columns_for_association(name, options)
        col_names = options[:select]

        return send(Inflecto.pluralize(name)).qualified_columns unless col_names

        relations = col_names.is_a?(Hash) ? col_names.keys : [name]

        columns = relations.each_with_object([]) do |rel_name, a|
          relation = send(Inflecto.pluralize(rel_name))
          names = col_names.is_a?(Hash) ? col_names[rel_name] : col_names

          a.concat(relation.select(*names).prefix.qualified_columns)
        end

        columns
      end

      module AssociationDSL

        def one_to_many(name, options)
          associations << [__method__, name, options.merge(relation: name)]
        end

        def many_to_many(name, options = {})
          associations << [__method__, name, options.merge(relation: name)]
        end

        def many_to_one(name, options = {})
          associations << [__method__, name, options.merge(relation: Inflecto.pluralize(name).to_sym)]
        end

        def finalize(relations, relation)
          associations.each do |*args, options|
            model = relation.model
            other = relations[options.fetch(:relation)].model

            model.public_send(*args, options.merge(class: other))
          end

          model.freeze

          super
        end

        def associations
          @associations ||= []
        end

      end
    end

  end
end
