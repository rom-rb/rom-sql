module ROM
  module Plugins
    module Relation
      module SQL
        module AutoCombine
          # @api private
          def self.included(klass)
            super
            klass.class_eval do
              include(InstanceInterface)
              extend(ClassInterface)
            end
          end

          module ClassInterface
            def inherited(klass)
              super
              klass.auto_curry :for_combine
              klass.auto_curry :preload
            end
          end

          module InstanceInterface
            # Default methods for fetching combined relation
            #
            # This method is used by default by `combine`
            #
            # @return [SQL::Relation]
            #
            # @api private
            def for_combine(spec)
              source_key, target_key, target =
                case spec
                when ROM::SQL::Association
                  [*spec.join_keys(__registry__).flatten, spec.call(__registry__)]
                else
                  [*spec.flatten, self]
                end

              target.preload(source_key, target_key)
            end

            # @api private
            def preload(source_key, target_key, source)
              where(target_key => source.map { |tuple| tuple[source_key] })
            end
          end
        end
      end
    end
  end
end

ROM.plugins do
  adapter :sql do
    register :auto_combine, ROM::Plugins::Relation::SQL::AutoCombine, type: :relation
  end
end
