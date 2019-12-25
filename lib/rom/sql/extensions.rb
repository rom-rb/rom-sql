# frozen_string_literal: true

require 'dry/core/extensions'

module ROM
  module SQL
    extend Dry::Core::Extensions

    register_extension(:postgres) do
      require 'rom/sql/extensions/postgres'
    end

    register_extension(:mysql) do
      require 'rom/sql/extensions/mysql'
    end

    register_extension(:sqlite) do
      require 'rom/sql/extensions/sqlite'
    end

    register_extension(:active_support_notifications) do
      require 'rom/sql/extensions/active_support_notifications'
    end

    register_extension(:rails_log_subscriber) do
      require 'rom/sql/extensions/rails_log_subscriber'
    end
  end
end
