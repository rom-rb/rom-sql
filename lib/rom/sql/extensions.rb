require 'dry/core/extensions'

module ROM
  module SQL
    extend Dry::Core::Extensions

    def self.available_extension?(database_type)
      @__available_extensions__.key?(database_type)
    end

    register_extension(:postgres) do
      require 'rom/sql/extensions/postgres'
    end

    register_extension(:active_support_notifications) do
      require 'rom/sql/extensions/active_support_notifications'
    end

    register_extension(:rails_log_subscriber) do
      require 'rom/sql/extensions/rails_log_subscriber'
    end
  end
end
