require 'sequel/database/logging'
require 'active_support/notifications'

module Sequel

  class Database

    def log_yield_with_instrumentation(sql, args = nil, &block)
      ActiveSupport::Notifications.instrument(
        'sql.rom',
        :sql => sql,
        :name => instrumentation_name,
        :binds => args
      ) do
        log_yield_without_instrumentation(sql, args, &block)
      end
    end

    alias_method :log_yield_without_instrumentation, :log_yield
    alias_method :log_yield, :log_yield_with_instrumentation

    private

    def instrumentation_name
      "ROM[#{database_type}]"
    end

  end
end
