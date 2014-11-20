module ROM
  module SQL

    module RelationExtension

      def self.extended(relation)
        relation.model.set_dataset(relation.dataset.clone)
      end

      def association_join(name)
        self.class.new(model.association_join(name).naked, header)
      end

      def association_left_join(name)
        self.class.new(model.association_left_join(name).naked, header)
      end

      def association_right_join(name)
        self.class.new(model.association_right_join(name).naked, header)
      end

      def association_full_join(name)
        self.class.new(model.association_full_join(name).naked, header)
      end
    end

  end
end
