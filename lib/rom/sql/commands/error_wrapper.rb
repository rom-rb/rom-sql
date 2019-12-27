# frozen_string_literal: true

module ROM
  module SQL
    module Commands
      # Shared error handler for all SQL commands
      #
      # @api private
      module ErrorWrapper
        # Handle Sequel errors and re-raise ROM-specific errors
        #
        # @return [Hash, Array<Hash>]
        #
        # @raise SQL::Error
        #
        # @api public
        def call(*args)
          super
        rescue *ERROR_MAP.keys => e
          raise ERROR_MAP.fetch(e.class, Error), e
        end

        alias_method :[], :call
      end
    end
  end
end
