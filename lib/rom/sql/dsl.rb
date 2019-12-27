# frozen_string_literal: true

require 'concurrent/map'
require 'rom/support/inflector'
require 'rom/constants'

module ROM
  module SQL
    # @api private
    class DSL < BasicObject
      # @!attribute [r] schema
      #   @return [SQL::Schema]
      attr_reader :schema

      # @!attribute [r] relations
      #   @return [Hash, RelationRegistry]
      attr_reader :relations

      # @!attribute [r] picked_relations
      #   @return [Concurrent::Map]
      attr_reader :picked_relations

      # @api private
      def initialize(schema)
        @schema = schema
        @relations = schema.respond_to?(:relations) ? schema.relations : EMPTY_HASH
        @picked_relations = ::Concurrent::Map.new
      end

      # @api private
      def call(&block)
        arg, kwargs = select_relations(block.parameters)

        if kwargs.nil?
          result = instance_exec(arg, &block)
        else
          result = instance_exec(**kwargs, &block)
        end

        if result.is_a?(::Array)
          result
        else
          [result]
        end
      end

      # Return a string literal that will be used directly in an ORDER clause
      #
      # @param [String] value
      #
      # @return [Sequel::LiteralString]
      #
      # @api public
      def `(value)
        ::Sequel.lit(value)
      end

      # Returns a result of SQL EXISTS clause.
      #
      # @example
      #   users.where { exists(users.where(name: 'John')) }
      #   users.select_append { |r| exists(r[:posts].where(r[:posts][:user_id] => id)).as(:has_posts) }
      #
      # @api public
      def exists(relation)
        ::ROM::SQL::Attribute[Types::Bool].meta(sql_expr: relation.dataset.exists)
      end

      # @api private
      def respond_to_missing?(name, include_private = false)
        super || schema.key?(name)
      end

      private

      # @api private
      def type(identifier)
        type_name = Inflector.classify(identifier)
        types.const_get(type_name) if types.const_defined?(type_name)
      end

      # @api private
      def types
        ::ROM::SQL::Types
      end

      # @api private
      def select_relations(parameters)
        @picked_relations.fetch_or_store(parameters.hash) do
          keys = parameters.select { |type, _| type == :keyreq }

          if keys.empty?
            [relations, nil]
          else
            [nil, keys.each_with_object({}) { |(_, k), rs| rs[k] = relations[k] }]
          end
        end
      end
    end
  end
end
