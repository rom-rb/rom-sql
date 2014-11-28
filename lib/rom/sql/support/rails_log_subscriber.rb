require 'active_support/log_subscriber'

module ROM
  module SQL

    class RailsLogSubscriber < ActiveSupport::LogSubscriber

      def sql(event)
        debug "#{event.payload[:name]} (#{event.duration}) #{event.payload[:sql]}"
      end

    end

  end
end

ROM::SQL::RailsLogSubscriber.attach_to(:rom)
