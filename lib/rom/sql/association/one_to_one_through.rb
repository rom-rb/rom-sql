module ROM
  module SQL
    class Association
      class OneToOneThrough < Association
        option :through, reader: true, default: nil, accepts: [Symbol]

        def combine_keys(relations)
          source_key = relations[source].primary_key
          target_key = relations[through].foreign_key(source)

          { source_key => target_key }
        end

        def call(relations)
          left = relations[source]
          right = relations[through]
          tarel = relations[target]

          left_pk = left.primary_key
          right_fk = right.foreign_key(source)

          right_pk = right.primary_key
          target_fk = tarel.foreign_key(right)

          columns = tarel.header.qualified.to_a +
            left.header.project(left_pk).rename(left_pk => right_fk).qualified

          relation = left
            .inner_join(through, right_fk => left_pk)
            .inner_join(target, target_fk => right_pk )
            .select(*columns)
            .order(tarel.primary_key)

          relation.with(attributes: relation.columns)
        end
      end
    end
  end
end
