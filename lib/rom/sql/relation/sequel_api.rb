module ROM
  module SQL
    # Query API for SQL::Relation
    #
    # @api public
    module SequelAPI
      # Select specific columns for select clause
      #
      # @example
      #   users.select(:id, :name).first
      #   # {:id => 1, :name => "Jane" }
      #
      # @return [Relation]
      #
      # @api public
      def select(*args, &block)
        new(dataset.__send__(__method__, *args, &block))
      end

      # Append specific columns to select clause
      #
      # @example
      #   users.select(:id, :name).select_append(:email)
      #   # {:id => 1, :name => "Jane", :email => "jane@doe.org"}
      #
      # @param [Array<Symbol>] *args A list with column names
      #
      # @return [Relation]
      #
      # @api public
      def select_append(*args, &block)
        new(dataset.__send__(__method__, *args, &block))
      end

      # Restrict a relation to match criteria
      #
      # If block is passed it'll be executed in the context of a condition
      # builder object.
      #
      # @example
      #   users.where(name: 'Jane')
      #
      #   users.where { age >= 18 }
      #
      # @param [Hash] *args An optional hash with conditions for WHERE clause
      #
      # @return [Relation]
      #
      # @see http://sequel.jeremyevans.net/rdoc/files/doc/dataset_filtering_rdoc.html
      #
      # @api public
      def where(*args, &block)
        new(dataset.__send__(__method__, *args, &block))
      end

      # Restrict a relation to match grouping criteria
      #
      # @example
      #   users.with_task_count.having( task_count: 2 )
      #
      #   users.with_task_count.having { task_count > 3 }
      #
      # @param [Hash] *args An optional hash with conditions for HAVING clause
      #
      # @return [Relation]
      #
      # @see http://sequel.jeremyevans.net/rdoc/files/doc/dataset_filtering_rdoc.html
      #
      # @api public
      def having(*args, &block)
        new(dataset.__send__(__method__, *args, &block))
      end

      # Set order for the relation
      #
      # @example
      #   users.order(:name)
      #
      # @param [Array<Symbol>] *args A list with column names
      #
      # @return [Relation]
      #
      # @api public
      def order(*args, &block)
        new(dataset.__send__(__method__, *args, &block))
      end

      # Join with another relation using INNER JOIN
      #
      # @example
      #   users.inner_join(:tasks, id: :user_id)
      #
      # @param [Symbol] relation name
      # @param [Hash] join keys
      #
      # @return [Relation]
      #
      # @api public
      def inner_join(*args, &block)
        new(dataset.__send__(__method__, *args, &block))
      end

      # Join other relation using LEFT OUTER JOIN
      #
      # @example
      #   users.left_join(:tasks, id: :user_id)
      #
      # @param [Symbol] relation name
      # @param [Hash] join keys
      #
      # @return [Relation]
      #
      # @api public
      def left_join(*args, &block)
        new(dataset.__send__(__method__, *args, &block))
      end

      # Group by specific columns
      #
      # @example
      #   tasks.group(:user_id)
      #
      # @param [Array<Symbol>] *args A list of column names
      #
      # @return [Relation]
      #
      # @api public
      def group(*args, &block)
        new(dataset.__send__(__method__, *args, &block))
      end
    end
  end
end
