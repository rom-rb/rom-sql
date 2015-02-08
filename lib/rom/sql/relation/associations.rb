module ROM
  module SQL
    class Relation < ROM::Relation
      module Associations
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
          graph_join(name, :left_outer, options)
        end

        # @api private
        def graph_join(name, join_type, options = {})
          assoc = model.association_reflection(name)

          key = assoc[:key]
          type = assoc[:type]

          if type == :many_to_many
            select = options[:select] || {}
            graph_join_many_to_many(name, assoc, select)
          else
            graph_join_other(name, key, type, join_type, options)
          end
        end

        # @api private
        def graph(*args)
          __new__(dataset.__send__(__method__, *args))
        end

        private

        def graph_join_many_to_many(name, assoc, select)
          l_select, r_select =
            if select.is_a?(Hash)
              [select[assoc[:join_table]] || [], select[name]]
            else
              [[], select]
            end

          l_graph = graph(
            assoc[:join_table],
            { assoc[:left_key] => primary_key },
            select: l_select, implicit_qualifier: self.name
          )

          l_graph.graph(
            name, { primary_key => assoc[:right_key] }, select: r_select
          )
        end

        def graph_join_other(name, key, type, join_type, options)
          join_keys =
            if type == :many_to_one
              { primary_key => key }
            else
              { key => primary_key }
            end

          graph(
            name, join_keys,
            options.merge(join_type: join_type, implicit_qualifier: self.name)
          )
        end
      end
    end
  end
end
