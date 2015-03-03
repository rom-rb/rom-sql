module ROM
  module SQL
    class Relation < ROM::Relation
      module ClassMethods
        def inherited(klass)
          klass.class_eval do
            class << self
              attr_reader :model, :associations
            end
          end
          klass.instance_variable_set('@model', Class.new(Sequel::Model))
          klass.instance_variable_set('@associations', [])
          super
        end

        def one_to_many(name, options)
          associations << [__method__, name, options.merge(relation: name)]
        end

        def many_to_many(name, options = {})
          associations << [__method__, name, options.merge(relation: name)]
        end

        def many_to_one(name, options = {})
          relation_name = Inflector.pluralize(name).to_sym
          new_options = options.merge(relation: relation_name)
          associations << [__method__, name, new_options]
        end

        def finalize(relations, relation)
          model.set_dataset(relation.dataset)
          model.dataset.naked!

          associations.each do |*args, options|
            model = relation.model
            other = relations[options.fetch(:relation)].model

            model.public_send(*args, options.merge(class: other))
          end

          model.freeze

          super
        end
      end
    end
  end
end
