module ROM
  module SQL

    module RelationInclusion

      def self.included(klass)
        klass.class_eval { class << self; attr_accessor :model; end }
        klass.model = Class.new(Sequel::Model)

        klass.extend(AssociationDSL)
      end

      def model
        self.class.model
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
            model.public_send(*args, options.merge(class: relations[options[:relation]].model))
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
