# frozen_string_literal: true

require 'rom/sql/dsl'

module ROM
  module SQL
    # @api private
    class GroupDSL < DSL
      private

      # @api private
      def respond_to_missing?(_meth, _include_private = false)
        true
      end

      # @api private
      def method_missing(meth, ...)
        if schema.key?(meth)
          schema[meth].canonical
        else
          ::Sequel::VIRTUAL_ROW.__send__(meth.to_s, ...)
        end
      end
    end
  end
end
