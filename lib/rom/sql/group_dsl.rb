# frozen_string_literal: true

require 'rom/sql/dsl'

module ROM
  module SQL
    # @api private
    class GroupDSL < DSL
      private

      # @api private
      def method_missing(meth, *args, &block)
        if schema.key?(meth)
          schema[meth].canonical
        else
          ::Sequel::VIRTUAL_ROW.__send__(meth.to_s, *args, &block)
        end
      end
    end
  end
end
