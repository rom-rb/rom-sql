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

        private

        def method_missing(m, ...)
          connection.public_send(m, ...)
        end

        def respond_to_missing?(meth, include_private = false)
          connection.respond_to?(meth, include_private)
        end
      end
    end
  end
end
