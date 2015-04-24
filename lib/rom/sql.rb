require "sequel"
require "rom"

module ROM
  module SQL
    NoAssociationError = Class.new(StandardError)
    ConstraintError = Class.new(ROM::CommandError)

    class DatabaseError < ROM::CommandError
      attr_reader :original_exception

      def initialize(error, message)
        super(message)
        @original_exception = error
      end
    end
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
