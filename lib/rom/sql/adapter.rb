class Sequel::Dataset
  alias_method :header, :columns
end

module ROM
  module SQL

    module SequelExtension
      def self.extended(relation)
        relation.adapter_inclusions << AssociationMacros
        relation.adapter_extensions << AssociationJoins
      end
    end

    module AssociationMacros
      def self.included(klass)
        klass.class_eval { class << self; attr_accessor :__model__; end }
        klass.__model__ = Class.new(Sequel::Model)

        klass.extend(DSL)
      end

      def __model__
        self.class.__model__
      end

      module DSL
        def one_to_many(name, options)
          __model__.one_to_many(name, options.merge(class: send(name).__model__))
        end
      end
    end

    module AssociationJoins
      def self.extended(relation)
        relation.__model__.set_dataset(relation.dataset.clone)
        relation.__model__.freeze
      end

      def association_join(name)
        self.class.new(__model__.association_join(name).naked, header)
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
        tables.map do |table|
          [
            table,
            dataset(table),
            dataset(table).columns,
            SequelExtension
          ]
        end
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
