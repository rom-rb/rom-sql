require 'rom/schema/type'

module ROM
  module SQL
    class Type < ROM::Schema::Type
      # Return a new type marked as qualified
      #
      # @return [SQL::Type]
      #
      # @api public
      def qualified
        self.class.new(type.meta(qualified: true))
      end

      # Return if an attribute type is qualified
      #
      # @return [Boolean]
      #
      # @api public
      def qualified?
        meta[:qualified].equal?(true)
      end

      # @api private
      def sql_literal_append(ds, sql)
        identifier =
          if qualified? && aliased?
            :"#{source.dataset}__#{name}___#{meta[:alias]}"
          elsif qualified?
            :"#{source.dataset}__#{name}"
          elsif aliased?
            :"#{name}___#{meta[:alias]}"
          else
            name
          end

        ds.__send__(:literal_symbol_append, sql, identifier)
      end
    end
  end
end
