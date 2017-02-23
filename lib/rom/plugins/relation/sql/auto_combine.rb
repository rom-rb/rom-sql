module ROM
  module Plugins
    module Relation
      module SQL
        # @api private
        module AutoCombine
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
              klass.auto_curry :for_combine
              klass.auto_curry :preload
            end
          end

          # @api private
          module InstanceInterface
            # Default methods for fetching combined relation
            #
            # This method is used by default by `combine`
            #
            # @return [SQL::Relation]
            #
            # @api private
            def for_combine(spec)
              case spec
              when ROM::SQL::Association
                spec.call(__registry__, self).preload(spec)
              else
                preload(spec)
              end
            end

            # @api private
            def preload(spec, source)
              case spec
              when ROM::SQL::Association::ManyToOne
                pk = source.source[source.source.primary_key].qualified

                where(pk => source.pluck(pk.name))
              when Hash, ROM::SQL::Association
                source_key, target_key = spec.is_a?(Hash) ? spec.flatten(1) : spec.join_keys(__registry__).flatten(1)

                target_pks = source.pluck(source_key.to_sym)
                target_pks.uniq!

                where(target_key => target_pks)
              end
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
