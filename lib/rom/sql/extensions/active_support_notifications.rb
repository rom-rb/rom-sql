# frozen_string_literal: true

require 'sequel/database/logging'
require 'active_support/notifications'

module ROM
  module SQL
    module ActiveSupportInstrumentation
      def log_connection_yield(sql, _conn, args = nil)
        ActiveSupport::Notifications.instrument(
          'sql.rom',
          sql: sql,
          name: instrumentation_name,
          binds: args
        ) { super }
      end

      private

      def instrumentation_name
        "ROM[#{database_type}]"
      end
    end
  end
end

Sequel::Database.send(:prepend, ROM::SQL::ActiveSupportInstrumentation)
