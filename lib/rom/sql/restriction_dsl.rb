require 'rom/sql/expression'

module ROM
  module SQL
    class RestrictionDSL < BasicObject
      attr_reader :schema, :vr

      def initialize(schema)
        @schema = schema
        @vr = ::Sequel::VIRTUAL_ROW
      end

      def call(&block)
        instance_exec(&block)
      end

      private

      def method_missing(meth, *args, &block)
        if schema.key?(meth)
          ::ROM::SQL::Expression.new(schema[meth])
        else
          vr.__send__(meth, *args, &block)
        end
      end
    end
  end
end
