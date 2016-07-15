module ROM
  module SQL
    class Association
      class ManyToOne < Association
        result :one

        def associate(relations, child, parent)
          fk, pk = join_key_map(relations)
          child.merge(fk => parent.fetch(pk))
        end

        def combine_keys(relations)
          source_key = relations[source.relation].foreign_key(target.relation)
          target_key = relations[target.relation].primary_key

          { source_key => target_key }
        end

        def join_keys(relations)
          source_key = relations[source.relation].foreign_key(target.relation)
          target_key = relations[target.relation].primary_key

          { qualify(source, source_key) => qualify(target, target_key) }
        end

        def call(relations)
          left = relations[target.relation]
          right = relations[source.relation]

          right_pk = right.schema.primary_key.map { |a| a.meta[:name] }
          right_fk = right.foreign_key(target.relation)

          pk_to_fk = Hash[right_pk.product(Array(left.foreign_key(source.relation)))]

          columns = left.header.qualified.to_a + right.header
            .project(*right_pk)
            .rename(pk_to_fk)
            .qualified.to_a

          relation = left
            .inner_join(source, right_fk => left.primary_key)
            .select(*columns)
            .order(*right.header.project(*right.primary_key).qualified)

          relation.with(attributes: relation.header.names)
        end
      end
    end
  end
end
