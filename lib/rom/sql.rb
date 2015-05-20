require "sequel"
require "rom"

module ROM
  module SQL
    NoAssociationError = Class.new(StandardError)

    DatabaseError = Class.new(Sequel::DatabaseError)

    ConstraintError = Class.new(StandardError)
    NotNullConstraintError = Class.new(ConstraintError)
    UniqueConstraintError = Class.new(ConstraintError)
    ForeignKeyConstraintError = Class.new(ConstraintError)
    CheckConstraintError = Class.new(ConstraintError)
  end
end

require "rom/sql/version"
require "rom/sql/relation"
require "rom/sql/repository"
require "rom/sql/migration"

if defined?(Rails)
  require "rom/sql/support/active_support_notifications"
  require 'rom/sql/support/rails_log_subscriber'
end

ROM.register_adapter(:sql, ROM::SQL)

ROM.plugins do
  register :pagination, ROM::SQL::Plugin::Pagination, type: :relation
end
