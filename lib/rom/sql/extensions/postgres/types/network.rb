require 'ipaddr'

module ROM
  module SQL
    module Postgres
      module Types
        IPAddressR = SQL::Types.Constructor(IPAddr) { |ip| IPAddr.new(ip.to_s) }

        IPAddress = SQL::Types.Constructor(IPAddr, &:to_s).meta(read: IPAddressR)
      end
    end
  end
end
