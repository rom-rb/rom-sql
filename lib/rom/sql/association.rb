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

      class ManyToMany < Association
        option :through, reader: true, default: nil, accepts: [Symbol]

        def combine_keys(relations)
          left = relations[source].primary_key
          right = relations[through].schema.foreign_key(source).meta[:name]

          { left => right }
        end

        def call(relations)
          left = relations[source]
          right = relations[through]
          tarel = relations[target]

          left_pk = left.primary_key
          right_fk = right.schema.foreign_key(source).meta[:name]

          target_pk = tarel.primary_key
          target_fk = right.schema.foreign_key(target).meta[:name]

          columns = tarel.header.qualified.to_a +
            left.header.project(left_pk).rename(left_pk => right_fk).qualified

          left
            .inner_join(through, right_fk => left_pk)
            .inner_join(target, target_pk => target_fk)
            .select(*columns)
            .order(tarel.primary_key)
        end
      end
    end
  end
end
