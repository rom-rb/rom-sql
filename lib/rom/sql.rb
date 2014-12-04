require "sequel"
require "rom"

module ROM
  module SQL
    ConstraintError = Class.new(ROM::CommandError)
  end
end

require "rom/sql/version"
require "rom/sql/header"
require "rom/sql/relation_extension"
require "rom/sql/relation_inclusion"
require "rom/sql/adapter"

require "rom/sql/support/sequel_dataset_ext"

if defined?(Rails)
  require "rom/sql/support/active_support_notifications"
  require 'rom/sql/support/rails_log_subscriber'
end
