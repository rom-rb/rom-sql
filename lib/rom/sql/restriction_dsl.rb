require 'rom/sql/dsl'

module ROM
  module SQL
    class RestrictionDSL < DSL
      # @api private
      def call(&block)
        instance_exec(&block)
      end

      private

      # @api private
      def method_missing(meth, *args, &block)
        if schema.key?(meth)
          schema[meth]
        else
          ::Sequel::VIRTUAL_ROW.__send__(meth, *args, &block)
        end
      end
    end
  end
end
