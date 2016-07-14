module ROM
  module SQL
    class Association
      class ManyToMany < Association
        attr_reader :through

        result :many

        option :through, default: nil, type: Symbol

        def initialize(*)
          super
          @through = Relation::Name[
            options[:through] || options[:through_relation], options[:through]
          ]
        end

        def associate(relations, children, parent)
          ((spk, sfk), (tfk, tpk)) = join_key_map(relations)

          children.map { |tuple|
            { sfk => tuple.fetch(spk), tfk => parent.fetch(tpk) }
          }
        end

        def join_relation(relations)
          relations[through]
        end

        def join_key_map(relations)
          left = super
          right = join_relation(relations)
            .associations[target].join_key_map(relations)

          [left, right]
        end

        def combine_keys(relations)
          source_key = relations[source].primary_key
          target_key = relations[through].foreign_key(source)

          { source_key => target_key }
        end

        def join_keys(relations)
          source_key = relations[source.relation].primary_key
          target_key = relations[through.relation].foreign_key(source)

          { qualify(source, source_key) => qualify(through, target_key) }
        end

        def call(relations)
          join_rel = join_relation(relations)
          assocs = join_rel.associations

          # TODO: figure out a way so that we don't have to check which join assoc
          #       exists
          left = (assocs.key?(target) ? assocs[target] : assocs[target.singularize]).call(relations)
          right = relations[target.relation]

          left_fk = join_rel.foreign_key(source.relation)
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
