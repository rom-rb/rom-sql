require 'rom/sql/schema/index_dsl'

module ROM
  module SQL
    class Schema < ROM::Schema
      # @api public
      class DSL < ROM::Schema::DSL
        attr_reader :index_dsl

        def indexes(&block)
          @index_dsl = IndexDSL.new(options, &block)
        end

        def opts
          if index_dsl
            opts = super

            { **opts, indexes: index_dsl.(relation, opts[:attributes]) }
          else
            super
          end
        end
      end
    end
  end
end
