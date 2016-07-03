module ROM
  module SQL
    class QualifiedName
      include Dry::Equalizer(:dataset, :attribute)

      attr_reader :dataset

      attr_reader :attribute

      def initialize(dataset, attribute)
        @dataset = dataset
        @attribute = attribute
      end

      def sql_literal_append(ds, sql)
        ds.qualified_identifier_sql_append(sql, dataset, attribute)
      end
    end
  end
end
