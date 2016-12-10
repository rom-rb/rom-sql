require 'rom/schema/type'

module ROM
  module SQL
    class Type < ROM::Schema::Type
      # @api private
      def sql_literal_append(ds, sql)
        ds.__send__(:literal_symbol_append, sql, :"#{source.dataset}__#{name}")
      end
    end
  end
end
