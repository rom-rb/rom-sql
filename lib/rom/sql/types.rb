require 'dry-types'

module ROM
  module SQL
    module Types
      include Dry::Types.module

      Serial = Strict::Int.constrained(gt: 0).meta(primary_key: true)
    end
  end
end
