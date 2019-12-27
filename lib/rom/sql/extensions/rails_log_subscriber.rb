# frozen_string_literal: true

require 'active_support/log_subscriber'

module ROM
  module SQL
    class RailsLogSubscriber < ActiveSupport::LogSubscriber
      def sql(event)
        return unless logger.debug?

        payload = event.payload

        name = format('%s (%.1fms)', payload[:name], event.duration)
        sql  = payload[:sql].squeeze(' ')
        binds = payload[:binds].to_a.inspect if payload[:binds]

        if odd?
          name = color(name, :cyan, true)
          sql  = color(sql, nil, true)
        else
          name = color(name, :magenta, true)
        end

        debug "  #{name}  #{sql}  #{binds}"
      end

      attr_reader :odd_or_even
      private :odd_or_even
      def odd?
        @odd_or_even = !odd_or_even
      end
    end
  end
end

ROM::SQL::RailsLogSubscriber.attach_to(:rom)
