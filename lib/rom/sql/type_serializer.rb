# frozen_string_literal: true

require 'dry/core/class_attributes'

module ROM
  module SQL
    # @api private
    class TypeSerializer
      extend Dry::Core::ClassAttributes

      defines :registry

      def self.register(db_type, builder)
        registry[db_type] = builder
      end

      def self.[](db_type)
        registry[db_type]
      end

      registry Hash.new(new.freeze)

      defines :mapping

      mapping(
        Types::Integer => 'integer',
        Types::String => 'varchar',
        Types::Time => 'timestamp',
        Types::Date => 'date',
        Types::Bool => 'boolean',
        Types::Decimal => 'numeric',
        Types::Float => 'float',
      )

      def call(type)
        return type.meta[:db_type] if type.meta[:db_type]

        meta = type.meta[:read] ? { read: type.meta[:read] } : EMPTY_HASH

        self.class.mapping.fetch(type.with(meta: meta)) {
          if block_given?
            yield(type)
          end or raise "Cannot serialize #{ type }"
        }
      end
    end
  end
end
