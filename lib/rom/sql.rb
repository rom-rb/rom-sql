require "sequel"
require "rom"

module ROM
  module SQL
    NoAssociationError = Class.new(StandardError)

    class Error < StandardError
      attr_reader :original_exception

      def initialize(original_exception)
        super(original_exception.message)
        @original_exception = original_exception
        set_backtrace(original_exception.backtrace)
      end
    end

    DatabaseError = Class.new(Error)

    ConstraintError = Class.new(Error)

    NotNullConstraintError = Class.new(ConstraintError)
    UniqueConstraintError = Class.new(ConstraintError)
    ForeignKeyConstraintError = Class.new(ConstraintError)
    CheckConstraintError = Class.new(ConstraintError)

    ERROR_MAP = {
      Sequel::DatabaseError => DatabaseError,
      Sequel::NotNullConstraintViolation => NotNullConstraintError,
      Sequel::UniqueConstraintViolation => UniqueConstraintError,
      Sequel::ForeignKeyConstraintViolation => ForeignKeyConstraintError,
      Sequel::CheckConstraintViolation => CheckConstraintError
    }.freeze
  end
end

require 'rom/sql/plugin/associates'
require 'rom/sql/plugin/pagination'

ROM.plugins do
  adapter :sql do
    register :pagination, ROM::SQL::Plugin::Pagination, type: :relation
    register :associates, ROM::SQL::Plugin::Associates, type: :command
  end
end

require "rom/sql/version"
require "rom/sql/gateway"
require "rom/sql/relation"
require "rom/sql/migration"

if defined?(Rails)
  require "rom/sql/support/active_support_notifications"
  require 'rom/sql/support/rails_log_subscriber'
end

ROM.register_adapter(:sql, ROM::SQL)
