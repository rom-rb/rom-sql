module ROM
  module SQL
    class Association
      class OneToMany < Association
        result :many

        # @api public
        def call(relations, right = relations[target.relation])
          schema = right.schema.qualified

          relation = right.inner_join(source_table, join_keys(relations))

          if view
            apply_view(schema, relation)
          else
            schema.(relation)
          end
        end

        # @api public
        def combine_keys(relations)
          Hash[*with_keys(relations)]
        end

        # @api public
        def join_keys(relations)
          with_keys(relations) { |source_key, target_key|
            { qualify(source_alias, source_key) => qualify(target, target_key) }
          }
        end

        # @api private
        def associate(relations, child, parent)
          pk, fk = join_key_map(relations)
          child.merge(fk => parent.fetch(pk))
        end

        protected

        # @api private
        def source_table
          self_ref? ? Sequel.as(source.dataset, source_alias) : source
        end

        # @api private
        def source_alias
          self_ref? ? :"#{source.dataset.to_s[0]}_0" : source
        end

        # @api private
        def with_keys(relations, &block)
          source_key = relations[source.relation].primary_key
          target_key = foreign_key || relations[target.relation].foreign_key(source.relation)
          return [source_key, target_key] unless block
          yield(source_key, target_key)
        end
      end
    end
  end
end
