ROM::SQL.register_extension(:postgres) do
  require 'rom/sql/extensions/postgres'
end

ROM::SQL.register_extension(:active_support_notifications) do
  require 'rom/sql/extensions/active_support_notifications'
end

ROM::SQL.register_extension(:rails_log_subscriber) do
  require 'rom/sql/extensions/rails_log_subscriber'
end
