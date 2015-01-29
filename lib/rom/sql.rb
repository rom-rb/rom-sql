require "sequel"
require "rom"

module ROM
  module SQL
    ConstraintError = Class.new(ROM::CommandError)
  end
end

require "rom/sql/version"
require "rom/sql/header"
require "rom/sql/relation"
require "rom/sql/repository"
require "rom/sql/migration"

require "rom/sql/support/sequel_dataset_ext"

if defined?(Rails)
  require "rom/sql/support/active_support_notifications"
  require 'rom/sql/support/rails_log_subscriber'
end

ROM.register_adapter(:sql, ROM::SQL)
