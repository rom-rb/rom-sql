module ROM
  module SQL
    class Association
      class ManyToMany < Association
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

          target_pk = tarel.primary_key
          target_fk = right.foreign_key(target)

          columns = tarel.header.qualified.to_a +
            left.header.project(left_pk).rename(left_pk => right_fk).qualified

          relation = left
            .inner_join(through, right_fk => left_pk)
            .inner_join(target, target_pk => target_fk)
            .select(*columns)
            .order(tarel.primary_key)

          relation.with(attributes: relation.columns)
        end
      end
    end
  end
end
