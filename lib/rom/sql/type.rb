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

      # @api private
      def sql_literal_append(ds, sql)
        ds.__send__(:literal_symbol_append, sql, :"#{source.dataset}__#{name}")
      end
    end
  end
end
