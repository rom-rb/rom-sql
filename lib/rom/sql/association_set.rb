require 'rom/support/registry'

module ROM
  module SQL
    class AssociationSet < ROM::Registry
      # @api private
      def try(name, &block)
        if key?(name)
          yield(self[name])
        else
          false
        end
      end
    end
  end
end
