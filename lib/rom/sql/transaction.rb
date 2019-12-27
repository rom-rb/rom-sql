# frozen_string_literal: true

module ROM
  module SQL
    # @api private
    class Transaction < ::ROM::Transaction
      attr_reader :connection
      private :connection

      def initialize(connection)
        @connection = connection
      end

      def run(opts = EMPTY_HASH)
        connection.transaction(opts) { yield(self) }
      rescue ::ROM::Transaction::Rollback
        # noop
      end
    end
  end
end
