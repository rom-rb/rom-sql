module ROM
  module SQL
    class Association
      class OneToOne < Association
        def combine_keys(relations)
          source_key = relations[source].primary_key
          target_key = relations[target].foreign_key(source)

          { source_key => target_key }
        end

        def call(relations)
          left = relations[source]
          right = relations[target]

          left_pk = left.primary_key
          right_fk = right.foreign_key(source)

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
