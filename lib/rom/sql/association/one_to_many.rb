module ROM
  module SQL
    class Association
      class OneToMany < Association
        # @api public
        def call(right = self.target)
          schema = right.schema.qualified
          relation = right.join(source_table, join_keys)

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
          pk, fk = join_key_map
          child.merge(fk => parent.fetch(pk))
        end

        protected

        # @api private
        def source_table
          self_ref? ? Sequel.as(source.name.dataset, source_alias) : source.name.dataset
        end

        # @api private
        def source_alias
          self_ref? ? :"#{source.dataset.to_s[0]}_0" : source.name.dataset
        end

        # @api private
        def with_keys(&block)
          source_key = source.schema.primary_key_name
          target_key = foreign_key || target.foreign_key(source.name)
          return [source_key, target_key] unless block
          yield(source_key, target_key)
        end
      end
    end
  end
end
