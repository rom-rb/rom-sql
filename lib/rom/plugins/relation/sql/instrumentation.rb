require 'rom/plugins/relation/instrumentation'

module ROM
  module Plugins
    module Relation
      module SQL
        # @api private
        module Instrumentation
          def self.included(klass)
            super

            klass.class_eval do
              include ROM::Plugins::Relation::Instrumentation

              # @api private
              def notification_payload(relation)
                super.merge(query: relation.dataset.sql)
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
    register :instrumentation, ROM::Plugins::Relation::SQL::Instrumentation, type: :relation
  end
end
