module ROM
  module SQL
    # Type-specific methods
    #
    # @api public
    module TypeExtensions
      class << self
        # Gets extensions for a type
        #
        # @param [Dry::Types::Type] type
        #
        # @return [Hash]
        #
        # @api public
        def [](type)
          unwrapped = type.optional? ? type.right : type
          @types[unwrapped.meta(sql_expr: nil)] || EMPTY_HASH
        end

        # Registers a set of operations supported for a specific type
        #
        # @example
        #   ROM::SQL::Attribute::TypeExtensions.register(ROM::SQL::Types::PG::JSONB) do
        #     def contain(type, expr, keys)
        #       Attribute[Types::Bool].meta(sql_expr: expr.pg_jsonb.contains(value))
        #     end
        #   end
        #
        # @param [Dry::Types::Type] type Type
        #
        # @api public
        def register(type, &block)
          raise ArgumentError, "Type #{ type } already registered" if @types.key?(type)
          mod = Module.new(&block)
          ctx = Object.new.extend(mod)
          functions = mod.public_instance_methods.each_with_object({}) { |m, ms| ms[m] = ctx.method(m) }
          @types[type.meta(sql_expr: nil)] = functions
        end
      end

      @types = {}
    end
  end
end
