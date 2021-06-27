# frozen_string_literal: true

require "rom/relation"

require "rom/sql/types"
require "rom/sql/schema"
require "rom/sql/attribute"
require "rom/sql/wrap"
require "rom/sql/transaction"

require "rom/sql/relation/reading"
require "rom/sql/relation/writing"

module ROM
  module SQL
    # Sequel-specific relation extensions
    #
    # @api public
    class Relation < ROM::Relation
      extend Dry::Core::ClassAttributes # TODO: only needed by pagination plugin

      include SQL
      include Writing
      include Reading

      config.wrap_class = SQL::Wrap

      configure(:component) do |config|
        config.adapter = :sql
      end

      configure(:schema) do |config|
        config.constant = SQL::Schema
        config.attr_class = SQL::Attribute
        config.inferrer = ROM::SQL::Schema::Inferrer.new.freeze
        config.plugins << :indexes
      end

      dataset(abstract: true) do |schema|
        table = opts[:from].first

        if db.table_exists?(table)
          select(*schema.qualified_projection)
            .order(*schema.project(*schema.primary_key_names).qualified)
        else
          self
        end
      end

      option :primary_key, default: -> { schema.primary_key_name }

      # Return relation that will load associated tuples of this relation
      #
      # This method is useful for defining custom relation views for relation
      # composition when you want to enhance default association query
      #
      # @example
      #   assoc(:tasks).where(tasks[:title] => "Task One")
      #
      # @param [Symbol] name The association name
      #
      # @return [Relation]
      #
      # @api public
      def assoc(name)
        associations[name].()
      end

      # Open a database transaction
      #
      # @param [Hash] opts
      # @option opts [Boolean] :auto_savepoint Automatically use a savepoint for Database#transaction calls inside this transaction block.
      # @option opts [Symbol] :isolation The transaction isolation level to use for this transaction, should be :uncommitted, :committed, :repeatable, or :serializable, used if given and the database/adapter supports customizable transaction isolation levels.
      # @option opts [Integer] :num_retries The number of times to retry if the :retry_on option is used. The default is 5 times. Can be set to nil to retry indefinitely, but that is not recommended.
      # @option opts [Proc] :before_retry Proc to execute before rertrying if the :retry_on option is used. Called with two arguments: the number of retry attempts (counting the current one) and the error the last attempt failed with.
      # @option opts [String] :prepare A string to use as the transaction identifier for a prepared transaction (two-phase commit), if the database/adapter supports prepared transactions.
      # @option opts [Class] :retry_on An exception class or array of exception classes for which to automatically retry the transaction. Can only be set if not inside an existing transaction. Note that this should not be used unless the entire transaction block is idempotent, as otherwise it can cause non-idempotent behavior to execute multiple times.
      # @option opts [Symbol] :rollback Can the set to :reraise to reraise any Sequel::Rollback exceptions raised, or :always to always rollback even if no exceptions occur (useful for testing).
      # @option opts [Symbol] :server The server to use for the transaction. Set to :default, :read_only, or whatever symbol you used in the connect string when naming your servers.
      # @option opts [Boolean] :savepoint Whether to create a new savepoint for this transaction, only respected if the database/adapter supports savepoints. By default Sequel will reuse an existing transaction, so if you want to use a savepoint you must use this option. If the surrounding transaction uses :auto_savepoint, you can set this to false to not use a savepoint. If the value given for this option is :only, it will only create a savepoint if it is inside a transacation.
      # @option opts [Boolean] :deferrable **PG 9.1+ only** If present, set to DEFERRABLE if true or NOT DEFERRABLE if false.
      # @option opts [Boolean] :read_only **PG only** If present, set to READ ONLY if true or READ WRITE if false.
      # @option opts [Symbol] :synchronous **PG only** if non-nil, set synchronous_commit appropriately. Valid values true, :on, false, :off, :local (9.1+), and :remote_write (9.2+).
      #
      # @yield [t] Transaction
      #
      # @return [Mixed]
      #
      # @api public
      def transaction(**opts, &block)
        Transaction.new(dataset.db).run(**opts, &block)
      end

      # Return raw column names
      #
      # @return [Array<Symbol>]
      #
      # @api private
      def columns
        @columns ||= dataset.columns
      end
    end
  end
end
