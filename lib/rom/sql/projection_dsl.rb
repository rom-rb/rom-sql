require 'rom/sql/dsl'
require 'rom/sql/function'

module ROM
  module SQL
    # @api private
    class ProjectionDSL < DSL
      # @api public
      def `(value)
        expr = ::Sequel.lit(value)
        ::ROM::SQL::Attribute.new(type(:string)).meta(sql_expr: expr)
      end

      # @api private
      def respond_to_missing?(name, include_private = false)
        super || type(name)
      end

      private

      # @api private
      def method_missing(meth, *args, &block)
        if schema.key?(meth)
          schema[meth]
        else
          type = type(meth)

          if type
            ::ROM::SQL::Function.new(type)
          else
            super
          end
        end
      end
    end
  end
end
