require 'rom/sql/plugin/assoc_macros/class_interface'

module ROM
  module SQL
    module Plugin
      module AssocMacros
        # Extends a relation class with assoc-macros and instance-level methods
        #
        # @api private
        def self.included(relation)
          super
          relation.extend(ClassInterface)
        end

        # @api private
        def model
          self.class.model
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
          graph_join(name, :left_outer, options)
        end

        # @api private
        def graph_join(assoc_name, join_type, options = {})
          assoc = model.association_reflection(assoc_name)

          if assoc.nil?
            raise NoAssociationError,
              "Association #{assoc_name.inspect} has not been " \
              "defined for relation #{name.relation.inspect}"
          end

          type = assoc[:type]
          table_name = assoc[:class].table_name

          graph_rel =
            if type == :many_to_many
              select = options[:select] || {}
              graph_join_many_to_many(table_name, assoc, select)
            else
              graph_join_other(table_name, assoc, type, join_type, options)
            end

          graph_rel = graph_rel.where(assoc[:conditions]) if assoc[:conditions]

          graph_rel
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
            select: l_select, implicit_qualifier: self.name.dataset
          )

          l_graph.graph(
            name, { primary_key => assoc[:right_key] }, select: r_select
          )
        end

        def graph_join_other(name, assoc, type, join_type, options)
          key           = assoc[:key]
          on_conditions = assoc[:on] || {}

          join_keys =
            if type == :many_to_one
              { assoc[:class].primary_key => key }
            else
              { key => primary_key }
            end.merge(on_conditions)

          graph(
            name, join_keys,
            options.merge(join_type: join_type, implicit_qualifier: self.name.dataset)
          )
        end
      end
    end
  end
end
