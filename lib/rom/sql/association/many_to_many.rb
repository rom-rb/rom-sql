module ROM
  module SQL
    class Association
      class ManyToMany < Association
        result :many

        option :through, reader: true, default: nil, type: Symbol

        def combine_keys(relations)
          source_key = relations[source].primary_key
          target_key = relations[through].foreign_key(source)

          { source_key => target_key }
        end
        alias_method :join_keys, :combine_keys

        def call(relations)
          left = relations[through].schema.associations[target].call(relations)
          right = relations[target]

          left_fk = relations[through].foreign_key(source)
          columns = right.header.qualified.to_a + [left_fk]

          relation = left
            .inner_join(source, right.primary_key => left_fk)
            .select(*columns)
            .order(*right.header.project(*right.primary_key).qualified)

          relation.with(attributes: relation.header.names)
        end
      end
    end
  end
end
