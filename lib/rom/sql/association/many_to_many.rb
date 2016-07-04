module ROM
  module SQL
    class Association
      class ManyToMany < Association
        attr_reader :through

        result :many

        option :through, default: nil, type: Symbol

        def initialize(*)
          super

          @through = Relation::Name.new(options[:through] || options[:through_relation],
                                        options[:through])
        end

        def combine_keys(relations)
          source_key = relations[source.relation].primary_key
          target_key = relations[through.relation].foreign_key(source)

          { source_key => target_key }
        end

        def join_keys(relations)
          source_key = relations[source.relation].primary_key
          target_key = relations[through.relation].foreign_key(source)

          { qualify(source, source_key) => qualify(through, target_key) }
        end

        def call(relations)
          left = relations[through.relation].schema.associations[target.dataset].call(relations)
          right = relations[target.relation]

          left_fk = relations[through.relation].foreign_key(source)
          columns = right.header.qualified.to_a + [left_fk]

          relation = left
            .inner_join(source.dataset, right.primary_key => left_fk)
            .select(*columns)
            .order(*right.header.project(*right.primary_key).qualified)

          relation.with(attributes: relation.header.names)
        end
      end
    end
  end
end
