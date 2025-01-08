# frozen_string_literal: true

module ROM
  module SQL
    module Migration
      # @api private
      class Recorder
        attr_reader :operations

        def initialize(&)
          @operations = []

          instance_exec(&) if block_given?
        end

        private

        def respond_to_missing?(_m, _include_private = false)
          true
        end

        def method_missing(m, *args, &)
          nested = block_given? ? Recorder.new(&).operations : EMPTY_ARRAY
          @operations << [m, args, nested]
        end
      end
    end
  end
end
