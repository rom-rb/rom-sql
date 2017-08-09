require 'rom/attribute'

module ROM
  module SQL
    # @api public
    class Function < ROM::Attribute
      class << self
        # @api private
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

      # @api private
      WINDOW_FRAMES = Hash.new do |cache, frame|
        type = frame.key?(:rows) ? 'ROWS' : 'RANGE'
        bounds = frame[:rows] || frame[:range]
        cache[frame] = "#{ type } BETWEEN #{ frame_limit(bounds[0]) } AND #{ frame_limit(bounds[1])  }"
      end

      WINDOW_FRAMES[nil] = nil
      WINDOW_FRAMES[:all] = WINDOW_FRAMES[rows: [:start, :end]]
      WINDOW_FRAMES[:rows] = WINDOW_FRAMES[rows: [:start, :current]]
      WINDOW_FRAMES[range: :current] = WINDOW_FRAMES[range: [:current, :current]]

      # @api private
      def sql_literal(ds)
        if name
          ds.literal(func.as(name))
        else
          ds.literal(func)
        end
      end

      # @api private
      def name
        meta[:alias] || super
      end

      # @api private
      def qualified(table_alias = nil)
        meta(
          func: ::Sequel::SQL::Function.new(func.name, *func.args.map { |arg| arg.respond_to?(:qualified) ? arg.qualified(table_alias) : arg })
        )
      end

      # @api private
      def is(other)
        ::Sequel::SQL::BooleanExpression.new(:'=', func, other)
      end

      # Add an OVER clause making a window function call
      # @see https://www.postgresql.org/docs/9.6/static/tutorial-window.html
      #
      # @example
      #   users.select { [id, int::row_number().over(partition: name, order: id).as(:row_no)] }
      #   users.select { [id, int::row_number().over(partition: [first_name, last_name], order: id).as(:row_no)] }
      #
      # @example frame variants
      #   # ROWS BETWEEN 3 PRECEDING AND CURRENT ROW
      #   row_number.over(frame: { rows: [-3, :current] })
      #
      #   # ROWS BETWEEN 3 PRECEDING AND 3 FOLLOWING
      #   row_number.over(frame: { rows: [-3, 3] })
      #
      #   # ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
      #   row_number.over(frame: { rows: [:start, :current] })
      #
      #   # ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING
      #   row_number.over(frame: { rows: [:current, :end] })
      #
      # @example frame shortcuts
      #   # ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
      #   row_number.over(frame: :all)
      #
      #   # ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
      #   row_number.over(frame: :rows)
      #
      #   # RANGE BETWEEN CURRENT ROW AND CURRENT ROW
      #   row_number.over(frame: { range: :current} )
      #
      # @option :partition [Array<SQL::Attribute>,SQL::Attribute] A PARTITION BY part
      # @option :order [Array<SQL::Attribute>,SQL::Attribute] An ORDER BY part
      # @option :frame [Hash,Symbol] A frame part (RANGE or ROWS, see examples)
      # @return [SQL::Function]
      #
      # @api public
      def over(partition: nil, order: nil, frame: nil)
        super(partition: partition, order: order, frame: WINDOW_FRAMES[frame])
      end

      # Convert an expression result to another data type
      #
      # @example
      #   users.select { bool::cast(json_data.get_text('activated'), :boolean).as(:activated) }
      #   users.select { bool::cast(json_data.get_text('activated')).as(:activated) }
      #
      # @param [ROM::SQL::Attribute] expr Expression to be cast
      # @param [String] db_type Target database type (usually can be inferred from the target data type)
      #
      # @return [ROM::SQL::Attribute]
      #
      # @api public
      def cast(expr, db_type = TypeSerializer[:default].call(type))
        Attribute[type].meta(sql_expr: ::Sequel.cast(expr, db_type))
      end

      private

      # @api private
      def func
        meta[:func]
      end

      # @api private
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
