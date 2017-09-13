module ROM
  module SQL
    # Type-specific methods
    #
    # @api public
    module TypeExtensions
      class << self
        # Gets extensions for a type
        #
        # @param [Dry::Types::Type] wrapped
        #
        # @return [Hash]
        #
        # @api public
        def [](wrapped)
          type = wrapped.optional? ? wrapped.right : wrapped
          @types[type.meta[:database]][type.meta[:db_type]] || EMPTY_HASH
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
          extensions = @types[type.meta[:database]]
          db_type = type.meta[:db_type]

          raise ArgumentError, "Type #{ db_type } already registered" if extensions.key?(db_type)
          mod = Module.new(&block)
          ctx = Object.new.extend(mod)
          functions = mod.public_instance_methods.each_with_object({}) { |m, ms| ms[m] = ctx.method(m) }
          extensions[db_type] = functions
        end
      end

      @types = ::Hash.new do |hash, database|
        hash[database] = {}
      end
    end
  end
end
