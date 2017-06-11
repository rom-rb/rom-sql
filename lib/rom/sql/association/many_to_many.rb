require 'rom/types'

module ROM
  module SQL
    class Association
      class ManyToMany < Association
        attr_reader :join_relation

        # @api private
        def initialize(*)
          super
          @join_relation = relations[through]
        end

        # @api public
        def call(target_rel = nil)
          assocs = join_relation.associations

          left = target_rel ? assocs[target.name].(target_rel) : assocs[target.name].()
          right = target

          schema =
            if left.schema.key?(foreign_key)
              if target_rel
                target_rel.schema.merge(left.schema.project(foreign_key))
              else
                left.schema.project(*(right.schema.map(&:name) + [foreign_key]))
              end
            else
              right.schema.merge(join_relation.schema.project(foreign_key))
            end.qualified

          relation = left.join(source.name.dataset, join_keys)

          if view
            apply_view(schema, relation)
          else
            schema.(relation)
          end
        end

        # @api public
        def foreign_key
          definition.foreign_key || join_relation.foreign_key(source.name)
        end

        # @api public
        def through
          definition.through
        end

        # @api private
        def persist(children, parents)
          join_tuples = associate(children, parents)
          join_relation.multi_insert(join_tuples)
        end

        # @api private
        def parent_combine_keys
          target.associations[source.name].combine_keys.to_a.flatten(1)
        end

        # @api public
        def join(type, source = self.source, target = self.target)
          through_assoc = source.associations[through]
          joined = through_assoc.join(type, source)
          joined.__send__(type, target.name.dataset, join_keys).qualified
        end

        # @api public
        def join_keys
          with_keys { |source_key, target_key|
            { source[source_key].qualified => join_relation[target_key].qualified }
          }
        end

        # @api private
        def associate(children, parent)
          ((spk, sfk), (tfk, tpk)) = join_key_map

          case parent
          when Array
            parent.map { |p| associate(children, p) }.flatten(1)
          else
            children.map { |tuple|
              { sfk => tuple.fetch(spk), tfk => parent.fetch(tpk) }
            }
          end
        end

        protected

        # @api private
        def with_keys(&block)
          source_key = source.primary_key
          target_key = foreign_key || join_relation.foreign_key(source.name)
          return [source_key, target_key] unless block
          yield(source_key, target_key)
        end

        # @api private
        def join_key_map
          left = super
          right = join_relation.associations[target.name].join_key_map

          [left, right]
        end
      end
    end
  end
end
