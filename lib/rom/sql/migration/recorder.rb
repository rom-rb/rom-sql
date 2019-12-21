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

        def method_missing(m, *args, **kwargs, &block)
          nested = block ? Recorder.new(&block).operations : EMPTY_ARRAY
          @operations << [m, args, kwargs, nested]
        end
      end
    end
  end
end
