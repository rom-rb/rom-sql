# frozen_string_literal: true

require "dry/effects"
require "rom/sql/schema/index_dsl"

module ROM
  module SQL
    module Plugin
      module SchemaIndexes
        # @api public
        module DSL
          # Define indexes within a block
          #
          # @api public
          def indexes(&block)
            index_dsl.instance_eval(&block)
          end

          # @api private
          def configure
            super
            config.options.update(indexes: index_dsl.(config.id, attributes.values))
          end

          private

          # @api private
          def index_dsl
            @index_dsl ||= Schema::IndexDSL.new(attr_class: config.attr_class)
          end
        end
      end
    end
  end
end
