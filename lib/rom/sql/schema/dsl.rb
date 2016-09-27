require 'rom/sql/schema/inferrer'
require 'rom/sql/schema/associations_dsl'

module ROM
  module SQL
    class Schema < ROM::Schema
      class DSL < ROM::Schema::DSL
        attr_reader :associations_dsl

        def associations(&block)
          @associations_dsl = AssociationsDSL.new(name, &block)
        end

        def call
          SQL::Schema.new(name, attributes, opts)
        end

        def opts
          opts = { inferrer: inferrer }

          if associations_dsl
            { **opts, associations: associations_dsl.call }
          else
            opts
          end
        end
      end
    end
  end
end
