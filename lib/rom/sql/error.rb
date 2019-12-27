# frozen_string_literal: true

module ROM
  module SQL
    class Error < StandardError
      attr_reader :original_exception

      def initialize(original_exception)
        super(original_exception.message)
        @original_exception = original_exception
        set_backtrace(original_exception.backtrace)
      end
    end
  end
end
