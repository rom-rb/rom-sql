require 'rom/schema'
require 'rom/sql/association'

module ROM
  module SQL
    class Schema < ROM::Schema
      attr_reader :associations

      class AssociateDSL < BasicObject
        attr_reader :source, :associations

        def initialize(source, &block)
          @source = source
          @associations = {}
          instance_exec(&block)
        end

        def many(target, options = {})
          through = options[:through]

          if through
            @associations[target] = Association::ManyToMany.new(
              source, target, options.merge(through: associations[through] || through)
            )
          else
            @associations[target] = Association::OneToMany.new(source, target, options)
          end
        end

        def one(target, options = {})
          through = options[:through]

          if through
            @associations[target] = Association::OneToOneThrough.new(
              source, target, options.merge(through: associations[through] || through)
            )
          else
            @associations[target] = Association::OneToOne.new(source, target, options)
          end
        end

        def belongs(target)
          @associations[target] = Association::ManyToOne.new(source, target)
        end

        def call
          associations
        end
      end

      class DSL < ROM::Schema::DSL
        attr_reader :associations

        def associate(&block)
          @associations = AssociateDSL.new(dataset, &block)
        end

        def call
          SQL::Schema.new(dataset, attributes, associations && associations.call)
        end
      end

      def initialize(dataset, attributes, associations = {})
        @associations = associations
        super(dataset, attributes)
      end
    end
  end
end
