# frozen_string_literal: true

require 'active_support/log_subscriber'

module ROM
  module SQL
    class RailsLogSubscriber < ActiveSupport::LogSubscriber
      def sql(event)
        return unless logger.debug?

        payload = event.payload

        name = format("%s (%.1fms)", payload[:name], event.duration)
        sql  = payload[:sql].squeeze(" ")
        binds = payload[:binds].to_a.inspect if payload[:binds]

        if odd?
          name = color(name, :cyan, color_option)
          sql  = color(sql, nil, color_option)
        else
          name = color(name, :magenta, color_option)
        end

        debug "  #{name}  #{sql}  #{binds}"
      end

      attr_reader :odd_or_even
      private :odd_or_even

      def odd?
        @odd_or_even = !odd_or_even
      end

      private

      def color_option
        if Gem::Version.new(Rails::VERSION::STRING) >= Gem::Version.new('7.1')
          { color: true }
        else
          true
        end
      end
    end
  end
end

ROM::SQL::RailsLogSubscriber.attach_to(:rom)
