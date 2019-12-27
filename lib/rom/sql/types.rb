# frozen_string_literal: true

require 'sequel/core'
require 'sequel/sql'

require 'rom/types'
require 'rom/sql/type_dsl'

module ROM
  module SQL
    module Types
      include ROM::Types

      # Define a foreign key attribute type
      #
      # @example with default Int type
      #   attribute :user_id, Types.ForeignKey(:users)
      #
      # @example with a custom type
      #   attribute :user_id, Types.ForeignKey(:users, Types::UUID)
      #
      # @return [Dry::Types::Nominal]
      #
      # @api public
      def self.ForeignKey(relation, type = Types::Integer.meta(index: true))
        super
      end

      # Define a complex attribute type using Type DSL
      #
      # @example
      #   attribute :meta, Types.define(Types::JSON) do
      #     input { Types::PG::JSON }
      #     output { Types::Coercible::Hash }
      #   end
      #
      # @return [Dry::Types::Nominal]
      #
      # @api public
      def self.define(value_type, &block)
        TypeDSL.new(value_type).call(&block)
      end

      Serial = Integer.meta(primary_key: true)

      Blob = Constructor(Sequel::SQL::Blob, &Sequel::SQL::Blob.method(:new))

      Void = Nil
    end
  end
end
