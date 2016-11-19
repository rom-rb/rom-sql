require 'set'

module ROM
  module SQL
    module Plugin
      module Timestamps
        def self.included(klass)
          klass.extend(ClassInterface)
          super
        end

        module ClassInterface
          def self.extended(klass)
            klass.defines :timestamp_columns
            klass.timestamp_columns Set.new
            super
          end

          def timestamps(*args)
            timestamp_columns timestamp_columns.merge(args)

            include InstanceMethods
          end
          alias timestamp timestamps
        end

        module InstanceMethods
          # @api private
          def timestamp_columns
            self.class.timestamp_columns
          end

          def execute(tuples)
            timestamps = build_timestamps

            input_tuples = case tuples
                           when Hash
                             timestamps.merge(tuples)
                           when Array
                             tuples.map { |t| timestamps.merge(t) }
                           end

            super input_tuples
          end

          private

          # @api private
          def build_timestamps
            time        = Time.now.utc
            timestamps  = {}
            timestamp_columns.each do |column|
              timestamps[column.to_sym] = time
            end

            timestamps
          end
        end
      end
    end
  end
end
