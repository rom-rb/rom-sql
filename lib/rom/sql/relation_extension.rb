module ROM
  module SQL

    module RelationExtension
      attr_reader :model

      def self.extended(relation)
        relation.model.set_dataset(relation.dataset)
        relation.model.dataset.naked!
      end

    end

  end
end
