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
          alias_method :timestamp, :timestamps
        end

        module InstanceMethods

          # @api private
          def timestamp_columns
            self.class.timestamp_columns
          end

          def execute(tuples)
            time        = Time.now.utc.iso8601
            timestamps  = {}
            timestamp_columns.each do |column|
              timestamps[column.to_sym]  = time
            end

            super timestamps.merge(tuples)
          end
        end

      end
    end
  end
end
