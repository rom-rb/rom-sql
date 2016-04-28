module ROM
  module SQL
    class Association
      class ManyToOne < Association
        def combine_keys(relations)
          source_key = relations[source].foreign_key(target)
          target_key = relations[target].primary_key

          { source_key => target_key }
        end

        def call(relations)
          left = relations[source]
          right = relations[target]

          left_pk = left.foreign_key(target)
          right_fk = right.primary_key

          columns = right.header.qualified.to_a

          relation = right
            .inner_join(source, left_pk => right_fk)
            .select(*columns)
            .order(right.primary_key)

          relation.with(attributes: relation.columns)
        end
      end
    end
  end
end
