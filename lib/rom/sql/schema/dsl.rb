# frozen_string_literal: true

require 'rom/sql/schema/index_dsl'

module ROM
  module SQL
    class Schema < ROM::Schema
      # Specialized schema DSL with SQL-specific features
      #
      # @api public
      class DSL < ROM::Schema::DSL
        # @!attribute [r] index_dsl
        #   @return [IndexDSL] Index DSL instance (created only if indexes block is called)
        attr_reader :index_dsl

        # Define indexes within a block
        #
        # @api public
        def indexes(&block)
          @index_dsl = IndexDSL.new(**options, &block)
        end

        private

        # Return schema options
        #
        # @api private
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
