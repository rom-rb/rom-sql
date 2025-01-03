# frozen_string_literal: true

require 'rom/sql/dsl'

module ROM
  module SQL
    # @api private
    class OrderDSL < DSL
      private

      # @api private
      def method_missing(meth, ...)
        if schema.key?(meth)
          schema[meth]
        else
          ::Sequel::VIRTUAL_ROW.__send__(meth.to_s.upcase, ...)
        end
      end
    end
  end
end
