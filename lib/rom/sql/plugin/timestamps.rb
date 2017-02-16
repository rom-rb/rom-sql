require 'set'

module ROM
  module SQL
    module Plugin
      # Make a command that automatically fills in timestamp attributes on
      # input tuples
      #
      # @api private
      module Timestamps
        # @api private
        def self.included(klass)
          klass.extend(ClassInterface)
          super
        end

        module ClassInterface
          # @api private
          def self.extended(klass)
            klass.defines :timestamp_columns, :datestamp_columns
            klass.timestamp_columns Set.new
            klass.datestamp_columns Set.new

            super
          end

          # Set up attributes to timestamp when the command is called
          #
          # @example
          #   class CreateTask < ROM::Commands::Create[:sql]
          #     result :one
          #     use :timestamps
          #     timestamps :created_at, :updated_at
          #   end
          #
          #   create_user = rom.command(:user).create.with(name: 'Jane')
          #
          #   result = create_user.call
          #   result[:created_at]  #=> Time.now.utc
          #
          # @param [Symbol] name of the attribute to set
          #
          # @api public
          def timestamps(*args)
            timestamp_columns timestamp_columns.merge(args)

            include InstanceMethods
          end
          alias timestamp timestamps

          # Set up attributes to datestamp when the command is called
          #
          # @example
          #   class CreateTask < ROM::Commands::Create[:sql]
          #     result :one
          #     use :timestamps
          #     datestamps :created_on, :updated_on
          #   end
          #
          #   create_user = rom.command(:user).create.with(name: 'Jane')
          #
          #   result = create_user.call
          #   result[:created_at]  #=> Date.today
          #
          # @param [Symbol] name of the attribute to set
          #
          # @api public
          def datestamps(*args)
            datestamp_columns datestamp_columns.merge(args)

            include InstanceMethods
          end
          alias datestamp datestamps
        end

        module InstanceMethods
          # @api private
          def self.included(base)
            base.before :set_timestamps
          end

          # @api private
          def timestamp_columns
            self.class.timestamp_columns
          end

          # @api private
          def datestamp_columns
            self.class.datestamp_columns
          end

          # Set the timestamp attributes on the given tuples
          #
          # @param [Array<Hash>, Hash] tuples the input tuple(s)
          #
          # @return [Array<Hash>, Hash]
          #
          # @api private
          def set_timestamps(tuples, *)
            timestamps = build_timestamps

            case tuples
            when Hash
              timestamps.merge(tuples)
            when Array
              tuples.map { |t| timestamps.merge(t) }
            end
          end

          private

          # @api private
          def build_timestamps
            time        = Time.now.utc
            date        = Date.today
            timestamps  = {}
            timestamp_columns.each do |column|
              timestamps[column.to_sym] = time
            end

            datestamp_columns.each do |column|
              timestamps[column.to_sym] = date
            end

            timestamps
          end
        end
      end
    end
  end
end
