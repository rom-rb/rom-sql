module ROM
  module SQL
    class Association
      class OneToOne < Association
        result :one

        # @api public
        def call(relations)
          with_keys(relations) do |left_pk, right_fk|
            right = relations[target.relation]
            columns = right.header.qualified.to_a

            relation = right
              .inner_join(source, left_pk => right_fk)
              .select(*columns)
              .order(*right.header.project(*right.primary_key).qualified)

            relation.with(attributes: relation.header.names)
          end
        end

        # @api public
        def combine_keys(relations)
          Hash[*with_keys(relations)]
        end

        # @api public
        def join_keys(relations)
          with_keys(relations) { |source_key, target_key|
            { qualify(source, source_key) => qualify(target, target_key) }
          }
        end

        protected

        # @api private
        def with_keys(relations, &block)
          source_key = relations[source.relation].primary_key
          target_key = relations[target.relation].foreign_key(source.relation)
          return [source_key, target_key] unless block
          yield(source_key, target_key)
        end
      end
    end
  end
end
