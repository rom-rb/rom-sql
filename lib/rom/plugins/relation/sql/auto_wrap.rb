module ROM
  module Plugins
    module Relation
      module SQL
        # @api private
        module AutoWrap
          # @api private
          def self.included(klass)
            super
            klass.class_eval do
              include(InstanceInterface)
              extend(ClassInterface)
            end
          end

          # @api private
          module ClassInterface
            # @api private
            def inherited(klass)
              super
              klass.auto_curry :for_wrap
            end
          end

          # @api private
          module InstanceInterface
            # Default methods for fetching wrapped relation
            #
            # This method is used by default by `wrap` and `wrap_parents`
            #
            # @return [SQL::Relation]
            #
            # @api private
            def for_wrap(keys, name)
              other = __registry__[name]
              other_dataset = other.name.dataset

              schema.merge(other.schema.wrap).qualified.(inner_join(other_dataset, keys))
            end
          end
        end
      end
    end
  end
end

ROM.plugins do
  adapter :sql do
    register :auto_wrap, ROM::Plugins::Relation::SQL::AutoWrap, type: :relation
  end
end
