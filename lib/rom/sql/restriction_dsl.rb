require 'rom/sql/dsl'

module ROM
  module SQL
    # @api private
    class RestrictionDSL < DSL
      # @api private
      def call(&block)
        instance_exec(&block)
      end

      # Returns a result of SQL EXISTS clause.
      #
      # @example
      #   users.where { exists(users.where(name: 'John')) }
      def exists(relation)
        relation.dataset.exists
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
            ::Sequel::VIRTUAL_ROW.__send__(meth, *args, &block)
          end
        end
      end
    end
  end
end
