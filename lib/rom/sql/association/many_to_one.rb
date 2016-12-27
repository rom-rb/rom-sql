module ROM
  module SQL
    class Association
      class ManyToOne < Association
        result :one

        # @api public
        def call(relations)
          left = relations[target.relation]
          right = relations[source.relation]

          left_schema = left.schema
          right_schema = right.schema.project_pk

          left_fk = right_schema.foreign_key(target.relation)

          schema =
            if left_fk
              left_schema.merge(right_schema)
            else
              left_schema.merge(
                right_schema.rename(right.primary_key => left.foreign_key(source.relation))
              )
            end.qualified

          relation = left
            .inner_join(source, right.foreign_key(target.relation) => left.primary_key)
            .order(*right_schema.qualified)

          schema.(relation)
        end

        # @api public
        def combine_keys(relations)
          Hash[*with_keys(relations)]
        end

        # @api public
        def join_keys(relations)
          with_keys(relations) { |source_key, target_key|
            { qualify(source, source_key) => qualify(target, target_key) }
          }
        end

        # @api private
        def associate(relations, child, parent)
          fk, pk = join_key_map(relations)
          child.merge(fk => parent.fetch(pk))
        end

        protected

        # @api private
        def with_keys(relations, &block)
          source_key = relations[source.relation].foreign_key(target.relation)
          target_key = relations[target.relation].primary_key
          return [source_key, target_key] unless block
          yield(source_key, target_key)
        end
      end
    end
  end
end
