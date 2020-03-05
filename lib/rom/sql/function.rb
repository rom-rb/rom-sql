# frozen_string_literal: true

require 'rom/attribute'
require 'rom/sql/attribute_wrapping'

module ROM
  module SQL
    # Specialized attribute type for defining SQL functions
    #
    # @api public
    class Function < ROM::Attribute
      include AttributeWrapping

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

      # Return a new attribute with an alias
      #
      # @example
      #   string::coalesce(users[:name], users[:id]).aliased(:display_name)
      #
      # @return [SQL::Function]
      #
      # @api public
      def aliased(alias_name)
        super.with(name: name || alias_name)
      end
      alias_method :as, :aliased

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
        self.alias || super
      end

      # @see Attribute#qualified
      #
      # @api private
      def qualified(table_alias = nil)
        meta(
          func: ::Sequel::SQL::Function.new(func.name, *func.args.map { |arg| arg.respond_to?(:qualified) ? arg.qualified(table_alias) : arg })
        )
      end

      # @see Attribute#qualified_projection
      #
      # @api private
      def qualified_projection(table_alias = nil)
        meta(
          func: ::Sequel::SQL::Function.new(func.name, *func.args.map { |arg| arg.respond_to?(:qualified_projection) ? arg.qualified_projection(table_alias) : arg })
        )
      end

      # @see Attribute#qualified?
      #
      # @api private
      def qualified?(_table_alias = nil)
        meta[:func].args.all?(&:qualified?)
      end

      # @see ROM::SQL::Attribute#is
      #
      # @api public
      def is(other)
        ::ROM::SQL::Attribute[::ROM::SQL::Types::Bool].meta(
          sql_expr: ::Sequel::SQL::BooleanExpression.new(:'=', func, other)
        )
      end

      # @see ROM::SQL::Attribute#not
      #
      # @api public
      def not(other)
        !is(other)
      end

      # Add an OVER clause making a window function call
      # @see https://www.postgresql.org/docs/9.6/static/tutorial-window.html
      #
      # @example
      #   users.select { [id, integer::row_number().over(partition: name, order: id).as(:row_no)] }
      #   users.select { [id, integer::row_number().over(partition: [first_name, last_name], order: id).as(:row_no)] }
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

      # Add a CASE clause for handling if/then logic. This version of CASE search for the first
      # branch which evaluates to `true`. See SQL::Attriubte#case if you're looking for the
      # version that matches an expression result
      #
      # @example
      #   users.select { bool::case(status.is("active") => true, else: false).as(:activated) }
      #
      # @param [Hash] mapping mapping between boolean SQL expressions to arbitrary SQL expressions
      # @return [ROM::SQL::Attribute]
      #
      # @api public
      def case(mapping)
        mapping = mapping.dup
        otherwise = mapping.delete(:else) do
          raise ArgumentError, 'provide the default case using the :else keyword'
        end

        Attribute[type].meta(sql_expr: ::Sequel.case(mapping, otherwise))
      end

      # Add a FILTER clause to aggregate function (supported by PostgreSQL 9.4+)
      # @see https://www.postgresql.org/docs/current/static/sql-expressions.html
      #
      # Filter aggregate using the specified conditions
      #
      # @example
      #   users.project { integer::count(:id).filter(name.is("Jack")).as(:jacks) }.order(nil)
      #   users.project { integer::count(:id).filter { name.is("John") }).as(:johns) }.order(nil)
      #
      # @param condition [Hash,SQL::Attribute] Conditions
      # @yield [block] A block with restrictions
      #
      # @return [SQL::Function]
      #
      # @api public
      def filter(condition = Undefined, &block)
        if block
          conditions = schema.restriction(&block)
          conditions = conditions & condition unless condition.equal?(Undefined)
        else
          conditions = condition
        end

        super(conditions)
      end

      # Add a WITHIN GROUP clause to aggregate function (supported by PostgreSQL)
      # @see https://www.postgresql.org/docs/current/static/sql-expressions.html#SYNTAX-AGGREGATES
      #
      # Establishes an order for an ordered-set aggregate, see the docs for more details
      #
      # @example
      #   households.project { fload::percentile_cont(0.5).within_group(income).as(:percentile) }
      #
      # @param args [Array] A list of expressions for sorting within a group
      # @yield [block] A block for getting the expressions using the Order DSL
      #
      # @return [SQL::Function]
      #
      # @api public
      def within_group(*args, &block)
        if block
          group = args + ::ROM::SQL::OrderDSL.new(schema).(&block)
        else
          group = args
        end

        super(*group)
      end

      private

      # @api private
      def schema
        meta[:schema]
      end

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
