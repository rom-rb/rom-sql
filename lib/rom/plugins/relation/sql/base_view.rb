module ROM
  module Plugins
    module Relation
      module SQL
        module BaseView
          # @api private
          def self.included(klass)
            super
            klass.extend(ClassInterface)
          end

          module ClassInterface
            def inherited(klass)
              super
              klass.view(:base) do
                header { dataset.columns }
                relation { select(*attributes(:base)).order(primary_key) }
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
    register :base_view, ROM::Plugins::Relation::SQL::BaseView, type: :relation
  end
end
