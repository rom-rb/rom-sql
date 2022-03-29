# frozen_string_literal: true

require "rom/transaction"

module ROM
  module SQL
    # @api private
    class Transaction < ::ROM::Transaction
      attr_reader :connection
      private :connection

      def initialize(connection)
        @connection = connection
      end

      def run(**options)
        connection.transaction(options) { yield(self) }
      rescue ::ROM::Transaction::Rollback
        # noop
      end
    end
  end
end
