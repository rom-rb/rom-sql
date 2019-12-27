# frozen_string_literal: true

module ROM
  module SQL
    module Migration
      # @api private
      class Recorder
        attr_reader :operations

        def initialize(&block)
          @operations = []

          instance_exec(&block) if block
        end

        def method_missing(m, *args, &block)
          nested = block ? Recorder.new(&block).operations : EMPTY_ARRAY
          @operations << [m, args, nested]
        end
      end
    end
  end
end
