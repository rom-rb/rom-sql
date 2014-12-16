module ROM
  module SQL

    # Sequel-specific relation extensions
    #
    module RelationInclusion

      def self.included(klass)
        klass.extend(AssociationDSL)

        klass.send(:undef_method, :select)
        klass.send(:attr_reader, :model)

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

      def embed(name, options)
        select = options.fetch(:select)

        type = model.association_reflection(name)[:type]

        meth, as =
          if type == :many_to_one
            [:wrap, Inflecto.singularize(name).to_sym]
          else
            [:group, name]
          end

        joined = association_join(name, select: select)

        embedded_header = joined.header.map { |col|
          if col.respond_to?(:table) && col.table == name
            col.column
          elsif col.respond_to?(:expression) && col.expression.table == name
            col.aliaz
          end
        }.compact

        in_memory { send(meth, joined, as => embedded_header) }
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
      def association_join(name, options = {})
        graph_join(name, :inner, options)
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
      def association_left_join(name, options = {})
        graph_join(name, :left_outter, options)
      end

      # @api private
      def primary_key
        model.primary_key
      end

      # @api private
      def graph_join(name, join_type, options = {})
        assoc = model.association_reflection(name)

        key = assoc[:key]
        type = assoc[:type]

        if type == :many_to_many
          graph(assoc[:join_table], { assoc[:left_key] => primary_key }, select: [], implicit_qualifier: self.name).
            graph(name, { primary_key => assoc[:right_key] }, options)
        else
          join_keys =
            if type == :many_to_one
              { primary_key => key }
            else
              { key => primary_key }
            end

          graph(
            name,
            join_keys,
            options.merge(join_type: join_type, implicit_qualifier: self.name)
          )
        end
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
