require 'rom/sql/dsl'
require 'rom/sql/expression'

module ROM
  module SQL
    class RestrictionDSL < DSL
      def call(&block)
        instance_exec(&block)
      end

      private

      def method_missing(meth, *args, &block)
        if schema.key?(meth)
          ::ROM::SQL::Expression.new(schema[meth])
        else
          ::Sequel::VIRTUAL_ROW.__send__(meth, *args, &block)
        end
      end
    end
  end
end
