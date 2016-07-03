module ROM
  module SQL
    class Association
      class OneToOne < Association
        result :one

        def combine_keys(relations)
          source_key = relations[source.relation].primary_key
          target_key = relations[target.relation].foreign_key(source)

          { qualify(source, source_key) => qualify(target, target_key) }
        end
        alias_method :join_keys, :combine_keys

        def call(relations)
          left = relations[source.relation]
          right = relations[target.relation]

          left_pk = left.primary_key
          right_fk = right.foreign_key(source)

          columns = right.header.qualified.to_a

          relation = right
            .inner_join(source.dataset, left_pk => right_fk)
            .select(*columns)
            .order(*right.header.project(*right.primary_key).qualified)

          relation.with(attributes: relation.header.names)
        end
      end
    end
  end
end
