require 'rom/attribute'

module ROM
  module SQL
    # @api private
    class Function < ROM::Attribute
      class << self
        def frame_limit(value)
          case value
          when :current then 'CURRENT ROW'
          when :start then 'UNBOUNDED PRECEDING'
          when :end then 'UNBOUNDED FOLLOWING'
          else
            if value > 0
              "#{ value } FOLLOWING"
            else
              "#{ value.abs } PRECEDING"
            end
          end
        end

        private :frame_limit
      end

      WINDOW_FRAMES = Hash.new do |cache, frame|
        type = frame.key?(:rows) ? 'ROWS' : 'RANGE'
        bounds = frame[:rows] || frame[:range]
        cache[frame] = "#{ type } BETWEEN #{ frame_limit(bounds[0]) } AND #{ frame_limit(bounds[1])  }"
      end

      WINDOW_FRAMES[nil] = nil
      WINDOW_FRAMES[:all] = WINDOW_FRAMES[rows: [:start, :end]]
      WINDOW_FRAMES[:rows] = WINDOW_FRAMES[rows: [:start, :current]]
      WINDOW_FRAMES[range: :current] = WINDOW_FRAMES[range: [:current, :current]]

      def sql_literal(ds)
        if name
          ds.literal(func.as(name))
        else
          ds.literal(func)
        end
      end

      def name
        meta[:alias] || super
      end

      def qualified(table_alias = nil)
        meta(
          func: ::Sequel::SQL::Function.new(func.name, *func.args.map { |arg| arg.respond_to?(:qualified) ? arg.qualified(table_alias) : arg })
        )
      end

      def is(other)
        ::Sequel::SQL::BooleanExpression.new(:'=', func, other)
      end

      def over(partition: nil, order: nil, frame: nil)
        super(partition: partition, order: order, frame: WINDOW_FRAMES[frame])
      end

      # Convert an expression result to another data type
      #
      # @example
      #   users.select { bool::cast(json_data.get_text('activated'), :boolean).as(:activated) }
      #
      # @param [ROM::SQL::Attribute] expr Expression to be cast
      # @param [String] db_type Target database type
      #
      # @return [ROM::SQL::Attribute]
      #
      # @api private
      def cast(expr, db_type = TypeSerializer[:default].call(type))
        Attribute[type].meta(sql_expr: ::Sequel.cast(expr, db_type))
      end

      private

      def func
        meta[:func]
      end

      def method_missing(meth, *args)
        if func
          if func.respond_to?(meth)
            meta(func: func.__send__(meth, *args))
          else
            super
          end
        else
          meta(func: Sequel::SQL::Function.new(meth.to_s.upcase, *args))
        end
      end
    end
  end
end
