module ROM
  module SQL
    class Association
      include Dry::Equalizer(:source, :target, :options)
      include Options

      attr_reader :source
      attr_reader :target

      def initialize(source, target, options = {})
        @source = source
        @target = target
        super
      end

      class OneToOne < Association
        def combine_keys(relations)
          source_key = relations[source].primary_key
          target_key = relations[target].foreign_key(source)

          { source_key => target_key }
        end

        def call(relations)
          left = relations[source]
          right = relations[target]

          left_pk = left.primary_key
          right_fk = right.foreign_key(source)

          columns = right.header.qualified.to_a

          relation = left
            .inner_join(target, right_fk => left_pk)
            .select(*columns)
            .order(right.primary_key)

          relation.with(attributes: relation.columns)
        end
      end

      class OneToMany < OneToOne
      end

      class OneToOneThrough < Association
        option :through, reader: true, default: nil, accepts: [Symbol]

        def combine_keys(relations)
          source_key = relations[source].primary_key
          target_key = relations[through].foreign_key(source)

          { source_key => target_key }
        end

        def call(relations)
          left = relations[source]
          right = relations[through]
          tarel = relations[target]

          left_pk = left.primary_key
          right_fk = right.foreign_key(source)

          right_pk = right.primary_key
          target_fk = tarel.foreign_key(right)

          columns = tarel.header.qualified.to_a +
            left.header.project(left_pk).rename(left_pk => right_fk).qualified

          relation = left
            .inner_join(through, right_fk => left_pk)
            .inner_join(target, target_fk => right_pk )
            .select(*columns)
            .order(tarel.primary_key)

          relation.with(attributes: relation.columns)
        end
      end

      class ManyToOne < Association
        def combine_keys(relations)
          source_key = relations[source].foreign_key(target)
          target_key = relations[target].primary_key

          { source_key => target_key }
        end

        def call(relations)
          left = relations[source]
          right = relations[target]

          left_pk = left.foreign_key(target)
          right_fk = right.primary_key

          columns = right.header.qualified.to_a

          relation = left
            .inner_join(target, right_fk => left_pk)
            .select(*columns)
            .order(right.primary_key)

          relation.with(attributes: relation.columns)
        end
      end

      class ManyToMany < Association
        option :through, reader: true, default: nil, accepts: [Symbol]

        def combine_keys(relations)
          source_key = relations[source].primary_key
          target_key = relations[through].foreign_key(source)

          { source_key => target_key }
        end

        def call(relations)
          left = relations[source]
          right = relations[through]
          tarel = relations[target]

          left_pk = left.primary_key
          right_fk = right.foreign_key(source)

          target_pk = tarel.primary_key
          target_fk = right.foreign_key(target)

          columns = tarel.header.qualified.to_a +
            left.header.project(left_pk).rename(left_pk => right_fk).qualified

          relation = left
            .inner_join(through, right_fk => left_pk)
            .inner_join(target, target_pk => target_fk)
            .select(*columns)
            .order(tarel.primary_key)

          relation.with(attributes: relation.columns)
        end
      end
    end
  end
end
