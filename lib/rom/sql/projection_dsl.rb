# frozen_string_literal: true

require 'rom/sql/dsl'
require 'rom/sql/function'

module ROM
  module SQL
    # Projection DSL used in reading API (`select`, `select_append` etc.)
    #
    # @api public
    class ProjectionDSL < DSL
      # Return a string literal that will be directly used in an SQL statement or query
      #
      # @example
      #   users.select { `'FOO'`.as(:foo) }.first
      #   # => { :foo => "FOO" }
      #
      # @param [String] value A string object
      #
      # @return [Attribute] An SQL attribute with a string literal expression
      #
      # @api public
      def `(value)
        expr = ::Sequel.lit(value)
        ::ROM::SQL::Attribute.new(type(:string)).meta(sql_expr: expr)
      end

      # Return a SQL function with value `Any`
      #
      # @example
      #   users.select { function(:count, :id).as(:total) }
      #
      # @param [Symbol] name SQL function
      # @param [Symbol] attrs
      #
      # @return [Rom::SQL::Function]
      #
      # @api public
      def function(name, *attrs)
        ::ROM::SQL::Function.new(::ROM::Types::Any, schema: schema).public_send(name, *attrs)
      end
      alias_method :f, :function

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
            if args.empty?
              ::ROM::SQL::Function.new(type, schema: schema)
            else
              ::ROM::SQL::Attribute[type].value(args[0])
            end
          else
            super
          end
        end
      end
    end
  end
end
