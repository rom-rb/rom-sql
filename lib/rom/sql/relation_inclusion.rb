module ROM
  module SQL

    module RelationInclusion

      def self.included(klass)
        klass.extend(AssociationDSL)

        klass.send(:undef_method, :select)

        klass.class_eval {
          class << self
            attr_accessor :model
          end

          self.model = Class.new(Sequel::Model)
        }
      end

      def initialize(*args)
        super
        @model = self.class.model
      end

      module AssociationDSL

        def one_to_many(name, options)
          associations << [__method__, name, options.merge(relation: name)]
        end

        def many_to_many(name, options = {})
          associations << [__method__, name, options.merge(relation: name)]
        end

        def many_to_one(name, options = {})
          associations << [__method__, name, options.merge(relation: Inflecto.pluralize(name).to_sym)]
        end

        def finalize(relations, relation)
          associations.each do |*args, options|
            model = relation.model
            other = relations[options.fetch(:relation)].model

            model.public_send(*args, options.merge(class: other))
          end

          model.freeze

          super
        end

        def associations
          @associations ||= []
        end

      end
    end

  end
end
