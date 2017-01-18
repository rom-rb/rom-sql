require 'rom/types'

module ROM
  module SQL
    class Association
      class ManyToMany < Association
        result :many

        option :through, type: Types::Strict::Symbol.optional

        # @api private
        def initialize(*)
          super
          @through = Relation::Name[
            options[:through] || options[:through_relation], options[:through]
          ]
        end

        # @api public
        def call(relations, target_rel = nil)
          join_rel = join_relation(relations)
          assocs = join_rel.associations

          left = target_rel ? assocs[target].(relations, target_rel) : assocs[target].(relations)
          right = relations[target.relation]

          left_fk = foreign_key || join_rel.foreign_key(source.relation)

          schema =
            if left.schema.key?(left_fk)
              if target_rel
                target_rel.schema.merge(left.schema.project(left_fk))
              else
                left.schema.project(*(right.schema.map(&:name) + [left_fk]))
              end
            else
              right.schema.merge(join_rel.schema.project(left_fk))
            end.qualified

          relation = left
            .inner_join(source, join_keys(relations))
            .order(*right.schema.project_pk.qualified)

          if view
            schema.(relation.public_send(view))
          else
            schema.(relation)
          end
        end

        # @api public
        def join_keys(relations)
          with_keys(relations) { |source_key, target_key|
            { qualify(source, source_key) => qualify(through, target_key) }
          }
        end

        # @api public
        def combine_keys(relations)
          Hash[*with_keys(relations)]
        end

        # @api private
        def associate(relations, children, parent)
          ((spk, sfk), (tfk, tpk)) = join_key_map(relations)

          children.map { |tuple|
            { sfk => tuple.fetch(spk), tfk => parent.fetch(tpk) }
          }
        end

        # @api private
        def join_relation(relations)
          relations[through.relation]
        end

        protected

        # @api private
        def with_keys(relations, &block)
          source_key = relations[source.relation].primary_key
          target_key = foreign_key || relations[through.relation].foreign_key(source.relation)
          return [source_key, target_key] unless block
          yield(source_key, target_key)
        end

        # @api private
        def join_key_map(relations)
          left = super
          right = join_relation(relations).associations[target].join_key_map(relations)

          [left, right]
        end
      end
    end
  end
end
