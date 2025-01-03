# frozen_string_literal: true

module ROM
  module SQL
    module Migration
      # @api private
      class InlineRunner < BasicObject
        extend Initializer

        param :connection

        def migration
          yield(connection)
        end

        def method_missing(m, ...)
          connection.public_send(m, ...)
        end
      end
    end
  end
end
