module ROM
  module SQL

    module RelationInclusion

      def self.included(klass)
        klass.extend(AssociationDSL)

        klass.send(:undef_method, :select)

        klass.class_eval {
          class << self
            attr_accessor :model
          end

          self.model = Class.new(Sequel::Model)
        }
      end

      def initialize(*args)
        super
        @model = self.class.model
        @header = Header.new(header, name) if header.is_a?(Array)
      end

      def project(*names)
        new(:select, header.project(*names))
      end

      def rename(options)
        new(:select, header.rename(options))
      end

      def prefix(col_prefix = Inflecto.singularize(name))
        rename(header.prefix(col_prefix).to_h)
      end

      def qualified_columns
        header.qualified.to_a
      end

      private

      def new(method, header)
        self.class.new(dataset.public_send(method, *header), header)
      end

      module AssociationDSL

        def one_to_many(name, options)
          associations << [__method__, name, options.merge(relation: name)]
        end

        def many_to_many(name, options = {})
          associations << [__method__, name, options.merge(relation: name)]
        end

        def many_to_one(name, options = {})
          associations << [__method__, name, options.merge(relation: Inflecto.pluralize(name).to_sym)]
        end

        def finalize(relations, relation)
          associations.each do |*args, options|
            model = relation.model
            other = relations[options.fetch(:relation)].model

            model.public_send(*args, options.merge(class: other))
          end

          model.freeze

          super
        end

        def associations
          @associations ||= []
        end

      end
    end

  end
end
