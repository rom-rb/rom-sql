# frozen_string_literal: true

module ROM
  module SQL
    # @api private
    class ForeignKey
      extend Initializer
      include Dry::Equalizer(:attributes, :parent_table, :options)

      DEFAULT_PARENT_KEYS = %i[id].freeze

      param :attributes

      param :parent_table, type: Dry::Types['strict.symbol']

      option :parent_keys, default: -> { DEFAULT_PARENT_KEYS }
    end
  end
end
