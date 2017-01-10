require 'rom/sql/dsl'

module ROM
  module SQL
    class OrderDSL < DSL
      private

      # @api private
      def method_missing(meth, *args, &block)
        if schema.key?(meth)
          schema[meth].with_sql_expr
        else
          ::Sequel::VIRTUAL_ROW.__send__(meth, *args, &block)
        end
      end
    end
  end
end
