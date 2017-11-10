module ROM
  module Plugins
    module Relation
      module SQL
        # @api private
        module Instrumentation
          extend Notifications::Listener

          subscribe('configuration.relations.registry.created') do |event|
            registry = event[:registry]

            relations = registry.select { |_, r| r.adapter == :sql && r.respond_to?(:notifications) }.to_h
            db_notifications = relations.values.map { |r| [r.dataset.db, r.notifications] }.uniq.to_h

            db_notifications.each do |db, notifications|
              instrumenter = Instrumenter.new(db.database_type, notifications)
              db.extend(instrumenter)
            end
          end

          class Instrumenter < Module
            attr_reader :name
            attr_reader :notifications

            def initialize(name, notifications)
              @name = name
              @notifications = notifications
              define_log_connection_yield
            end

            private

            def define_log_connection_yield
              name = self.name
              notifications = self.notifications

              define_method(:log_connection_yield) do |*args, &block|
                notifications.instrument(:sql, name: name, query: args[0]) do
                  super(*args, &block)
                end
              end
            end
          end

          def self.included(klass)
            super
            klass.option :notifications
          end
        end
      end
    end
  end
end

ROM.plugins do
  adapter :sql do
    register :instrumentation, ROM::Plugins::Relation::SQL::Instrumentation, type: :relation
  end
end
