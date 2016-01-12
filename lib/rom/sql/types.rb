require 'dry-data'

module ROM
  module SQL
    module Types
      # FIXME: missing interface in dry-data
      Dry::Data.define_constants(self, Dry::Data.container._container.keys)

      Serial = Strict::Int.constrained(gt: 0)
    end
  end
end
