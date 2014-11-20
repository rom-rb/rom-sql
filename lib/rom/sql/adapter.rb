class Sequel::Dataset
  alias_method :header, :columns
end

module ROM
  module SQL

    module AssociationMacros
      def self.included(klass)
        klass.class_eval { class << self; attr_accessor :model; end }
        klass.model = Class.new(Sequel::Model)

        klass.extend(DSL)
      end

      def model
        self.class.model
      end

      module DSL
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
            model.public_send(*args, options.merge(class: relations[options[:relation]].model))
          end
          model.freeze
          super
        end

        def associations
          @associations ||= []
        end

      end
    end

    module AssociationJoins
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

    class Adapter < ROM::Adapter
      attr_reader :connection

      def self.schemes
        [:ado, :amalgalite, :cubrid, :db2, :dbi, :do, :fdbsql, :firebird, :ibmdb,
         :informix, :jdbc, :mysql, :mysql2, :odbc, :openbase, :oracle, :postgres,
         :sqlanywhere, :sqlite, :swift, :tinytds]
      end

      def initialize(*args)
        super
        @connection = ::Sequel.connect(uri.to_s)
      end

      def [](name)
        connection[name]
      end

      def schema
        tables.map { |table| [table, dataset(table), dataset(table).columns] }
      end

      def extend_relation_class(klass)
        klass.send(:include, AssociationMacros)
      end

      def extend_relation_instance(relation)
        relation.extend(AssociationJoins)
      end

      private

      def tables
        connection.tables
      end

      def dataset(table)
        connection[table]
      end

      def attributes(table)
        map_attribute_types connection.schema(table)
      end

      def map_attribute_types(attrs)
        attrs.map do |column, opts|
          [column, { type: map_schema_type(opts[:type]) }]
        end.to_h
      end

      def map_schema_type(type)
        connection.class::SCHEMA_TYPE_CLASSES.fetch(type)
      end

      ROM::Adapter.register(self)
    end

  end
end
