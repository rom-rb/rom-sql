require 'rom/sql/relation/class_methods'
require 'rom/sql/relation/inspection'
require 'rom/sql/relation/associations'

module ROM
  module SQL
    # Sequel-specific relation extensions
    #
    class Relation < ROM::Relation
      extend ClassMethods

      include Inspection
      include Associations

      undef_method :select

      def unique?(criteria)
        where(criteria).count.zero?
      end
    end
  end
end
