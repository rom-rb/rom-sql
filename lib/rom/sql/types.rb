require 'rom/types'

module ROM
  module SQL
    module Types
      include ROM::Types

      Serial = Strict::Int.constrained(gt: 0).meta(primary_key: true)

      String   = Types::Optional::Coercible::String
      Int      = Types::Optional::Coercible::Int
      Float    = Types::Optional::Coercible::Float
      Decimal  = Types::Optional::Coercible::Decimal
      Array    = Types::Optional::Coercible::Array
      Hash     = Types::Optional::Coercible::Hash

      Bool     = Types::Bool.optional
      Date     = Types::Date.constructor(->(date) { ::Date.parse(date.to_s) }).optional
      Time     = Types::Time.constructor(->(time) { ::Time.parse(time.to_s) }).optional
      DateTime = Types::DateTime.constructor(->(datetime) { ::DateTime.parse(datetime.to_s) }).optional
    end
  end
end
