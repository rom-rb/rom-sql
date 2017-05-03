require 'dry/equalizer'
require 'rom/relation/name'
require 'dry/core/cache'

module ROM
  module SQL
    class Association
      class Name
        include Dry::Equalizer.new(:relation_name, :key)

        extend Dry::Core::Cache

        attr_reader :relation_name

        attr_reader :key

        alias_method :to_sym, :key

        def self.[](*args)
          fetch_or_store(args) do
            rel, ds, aliaz = args

            if rel.is_a?(ROM::Relation::Name)
              new(rel, rel.dataset)
            elsif rel.is_a?(self)
              rel
            elsif aliaz
              new(ROM::Relation::Name[rel, ds], aliaz)
            elsif ds.nil?
              new(ROM::Relation::Name[rel], rel)
            else
              new(ROM::Relation::Name[rel, ds], ds)
            end
          end
        end

        def initialize(relation_name, aliaz)
          @relation_name = relation_name
          @aliased = relation_name.dataset != aliaz
          @key = aliased? ? aliaz : relation_name.dataset
        end

        def aliased?
          @aliased
        end

        def inspect
          if aliased?
            "#{self.class}(#{relation_name.to_s} as #{key})"
          else
            "#{self.class}(#{relation_name.to_s})"
          end
        end
        alias_method :to_s, :inspect

        def dataset
          relation_name.dataset
        end

        def relation
          relation_name.relation
        end

        def as(aliaz)
          Name[relation_name.relation, relation_name.dataset, aliaz]
        end

        def to_sym
          dataset
        end

        def sql_literal(ds)
          ds.literal(aliased? ? Sequel[dataset] : Sequel.as(dataset, key))
        end
      end
    end
  end
end
