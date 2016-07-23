module ROM
  module SQL
    class Association
      class ManyToMany < Association
        attr_reader :through

        result :many

        option :through, default: nil, type: Symbol

        # @api private
        def initialize(*)
          super
          @through = Relation::Name[
            options[:through] || options[:through_relation], options[:through]
          ]
        end

        # @api public
        def call(relations)
          join_rel = join_relation(relations)
          assocs = join_rel.associations

          left = assocs[target].call(relations)
          right = relations[target.relation]

          left_fk = join_rel.foreign_key(source.relation)

          columns = right.header.exclude(left_fk).qualified.to_a
          columns << left_fk unless right.header.names.include?(left_fk)

          relation = left
            .inner_join(source, join_keys(relations))
            .select(*columns)
            .order(*right.header.project(*right.primary_key).qualified)

          relation.with(attributes: relation.header.names)
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
          target_key = relations[through.relation].foreign_key(source.relation)
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
