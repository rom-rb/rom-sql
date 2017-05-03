module ROM
  module SQL
    class Association
      class ManyToOne < Association
        result :one

        # @api public
        def call(relations, left = relations[target.relation])
          right = relations[source.relation]

          left_pk = left.primary_key
          right_fk = left.foreign_key(source.relation)

          left_schema = left.schema
          right_schema = right.schema.project_pk

          schema =
            if left.schema.key?(right_fk)
              left_schema
            else
              left_schema.merge(right_schema.project_fk(left_pk => right_fk))
            end.qualified

          relation = left.inner_join(source_table, join_keys(relations))

          if view
            apply_view(schema, relation)
          else
            schema.(relation)
          end
        end

        # @api public
        def combine_keys(relations)
          Hash[*with_keys(relations)]
        end

        # @api public
        def join_keys(relations)
          with_keys(relations) { |source_key, target_key|
            { qualify(source_alias, source_key) => qualify(target, target_key) }
          }
        end

        # @api private
        def associate(relations, child, parent)
          fk, pk = join_key_map(relations)
          child.merge(fk => parent.fetch(pk))
        end

        protected

        # @api private
        def source_table
          self_ref? ? Sequel.as(source.dataset, source_alias) : source
        end

        # @api private
        def source_alias
          self_ref? ? :"#{source.dataset.to_s[0]}_0" : source
        end

        # @api private
        def with_keys(relations, &block)
          source_key = foreign_key || relations[source.relation].foreign_key(target.relation)
          target_key = relations[target.relation].primary_key
          return [source_key, target_key] unless block
          yield(source_key, target_key)
        end
      end
    end
  end
end
