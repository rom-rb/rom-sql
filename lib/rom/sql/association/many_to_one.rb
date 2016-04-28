module ROM
  module SQL
    class Association
      class ManyToOne < Association
        def combine_keys(relations)
          source_key = relations[target].primary_key
          target_key = relations[source].foreign_key(target)

          { source_key => target_key }
        end

        def call(relations)
          left = relations[source]
          right = relations[target]

          left_pk = left.foreign_key(target)
          right_fk = right.primary_key

          tarcols = right.header.qualified.to_a

          srccols = left
            .header
            .project(left.primary_key)
            .rename(left.primary_key => right.foreign_key(source))
            .qualified.to_a

          columns = tarcols + srccols

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
