module ROM
  module SQL
    module Plugin
      module Timestamps

        def self.included(klass)
          super
          klass.extend(ClassInterface)
        end

        module ClassInterface
          def inherited(klass)
            klass.defines :timestamp_columns
            klass.timestamp_columns []
            super
          end


          def timestamps(*args)
          end
          alias_method :timestamp, :timestamps
        end

        module InstanceMethods
        end

      end
    end
  end
end
