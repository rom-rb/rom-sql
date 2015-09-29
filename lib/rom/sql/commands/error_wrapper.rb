module ROM
  module SQL
    module Commands
      # Shared error handler for all SQL commands
      #
      # @api private
      module ErrorWrapper
        # Handle Sequel errors and re-raise ROM-specific errors
        #
        # @api public
        def call(*args)
          super
        rescue *ERROR_MAP.keys => e
          raise ERROR_MAP[e.class], e
        end

        alias_method :[], :call
      end
    end
  end
end
