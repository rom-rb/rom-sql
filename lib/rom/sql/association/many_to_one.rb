module ROM
  module SQL
    class Association
      class ManyToOne < Association
        result :one

        def combine_keys(relations)
          source_key = relations[target].primary_key
          target_key = relations[source].foreign_key(target)

          { source_key => target_key }
        end

        def join_keys(relations)
          source_key = relations[target].primary_key
          target_key = relations[source].foreign_key(target)

          { qualify(target, source_key) => qualify(source, target_key) }
        end

        def call(relations)
          left = relations[target]
          right = relations[source]

          right_pk = right.schema.primary_key.map { |a| a.meta[:name] }
          right_fk = right.foreign_key(target)

          pk_to_fk = Hash[right_pk.product(Array(left.foreign_key(source)))]

          columns = left.header.qualified.to_a + right.header.project(*right_pk).rename(pk_to_fk).qualified.to_a

          relation = left
            .inner_join(source.dataset, right_fk => left.primary_key)
            .select(*columns)
            .order(*right.header.project(*right.primary_key).qualified)

          relation.with(attributes: relation.header.names)
        end
      end
    end
  end
end
