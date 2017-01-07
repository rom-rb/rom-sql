require 'dry/core/inflector'
require 'rom/sql/association'

module ROM
  module SQL
    class Schema < ROM::Schema
      class AssociationsDSL < BasicObject
        attr_reader :source, :registry

        def initialize(source, &block)
          @source = source
          @registry = {}
          instance_exec(&block)
        end

        def one_to_many(target, options = {})
          if options[:through]
            many_to_many(target, options)
          else
            add(Association::OneToMany.new(source, target, options))
          end
        end
        alias_method :has_many, :one_to_many

        def one_to_one(target, options = {})
          if options[:through]
            one_to_one_through(target, options)
          else
            add(Association::OneToOne.new(source, target, options))
          end
        end

        def one_to_one_through(target, options = {})
          add(Association::OneToOneThrough.new(source, target, options))
        end

        def many_to_many(target, options = {})
          add(Association::ManyToMany.new(source, target, options))
        end

        def many_to_one(target, options = {})
          add(Association::ManyToOne.new(source, target, options))
        end

        def belongs_to(name, options = {})
          many_to_one(dataset_name(name), {as: name}.merge(options))
        end

        def has_one(name, options = {})
          one_to_one(dataset_name(name), {as: name}.merge(options))
        end

        def call
          AssociationSet.new(registry)
        end

        private

        def add(association)
          registry[association.name] = association
        end

        def dataset_name(name)
          ::Dry::Core::Inflector.pluralize(name).to_sym
        end
      end
    end
  end
end
