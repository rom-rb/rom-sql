require 'dry/equalizer'
require 'rom/relation/name'

module ROM
  module SQL
    class Association
      class Name
        include Dry::Equalizer.new(:relation_name, :key)

        attr_reader :relation_name

        attr_reader :key

        alias_method :to_sym, :key

        def self.[](*args)
          rel, ds, aliaz = args

          if rel.is_a?(ROM::Relation::Name)
            new(rel, rel.dataset)
          elsif aliaz
            new(ROM::Relation::Name[rel, ds], aliaz)
          elsif ds.nil?
            new(ROM::Relation::Name[rel], rel)
          else
            new(ROM::Relation::Name[rel, ds], ds)
          end
        end

        def initialize(relation_name, aliaz)
          @relation_name = relation_name
          @key = relation_name.dataset == aliaz ? relation_name.dataset : aliaz
          @aliased = key == aliaz
        end

        def aliased?
          @aliased
        end

        def inspect
          "#{self.class}(#{relation_name.to_s} as #{key})"
        end
        alias_method :to_s, :inspect

        def singularize
          :"#{Inflector.singularize(key.to_s)}"
        end

        def dataset
          relation_name.dataset
        end

        def relation
          relation_name.relation
        end

        def sql_literal_append(ds, sql)
          ds.literal_append(sql, dataset)
        end
      end
    end
  end
end
