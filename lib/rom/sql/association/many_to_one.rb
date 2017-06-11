module ROM
  module SQL
    class Association
      class ManyToOne < Association
        # @api public
        def call(left = self.target)
          right = source

          left_pk = left.schema.primary_key_name
          right_fk = left.foreign_key(source.name.relation)

          left_schema = left.schema
          right_schema = right.schema.project_pk

          schema =
            if left.schema.key?(right_fk)
              left_schema
            else
              left_schema.merge(right_schema.project_fk(left_pk => right_fk))
            end.qualified

          relation = left.join(source_table, join_keys)

          if view
            apply_view(schema, relation)
          else
            schema.(relation)
          end
        end

        # @api public
        def join_keys
          with_keys { |source_key, target_key|
            { source[source_key].qualified(source_alias) => target[target_key].qualified }
          }
        end

        # @api private
        def associate(child, parent)
          fk, pk = join_key_map
          child.merge(fk => parent.fetch(pk))
        end

        protected

        # @api private
        def source_table
          self_ref? ? Sequel.as(source.name.dataset, source_alias) : source.name.dataset
        end

        # @api private
        def source_alias
          self_ref? ? :"#{source.name.dataset.to_s[0]}_0" : source.name.dataset
        end

        # @api private
        def with_keys(&block)
          source_key = foreign_key || source.foreign_key(target.name.dataset)
          target_key = target.schema.primary_key_name
          return [source_key, target_key] unless block
          yield(source_key, target_key)
        end
      end
    end
  end
end
