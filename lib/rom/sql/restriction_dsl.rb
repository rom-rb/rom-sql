# frozen_string_literal: true

require 'rom/sql/dsl'

module ROM
  module SQL
    # @api private
    class RestrictionDSL < DSL
      # @api private
      def call(&block)
        arg, kwargs = select_relations(block.parameters)

        if kwargs.nil?
          instance_exec(arg, &block)
        else
          instance_exec(**kwargs, &block)
        end
      end

      private

      def respond_to_missing?(_meth, _include_private = false)
        true
      end

      # @api private
      def method_missing(meth, ...)
        if schema.key?(meth)
          schema[meth]
        else
          type = type(meth)

          if type
            ::ROM::SQL::Function.new(type).meta(schema: schema)
          else
            ::Sequel::VIRTUAL_ROW.__send__(meth, ...)
          end
        end
      end
    end
  end
end
