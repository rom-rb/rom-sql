require 'rom/schema'
require 'rom/sql/association'

module ROM
  module SQL
    class Schema < ROM::Schema
      include Dry::Equalizer(:name, :attributes, :associations)

      attr_reader :associations

      class SchemaInferrer
        extend ClassMacros

        defines :type_mapping, :pk_type

        type_mapping(
          integer: Types::Strict::Int,
          string: Types::Strict::String,
          date: Types::Strict::Date,
          datetime: Types::Strict::Time,
          boolean: Types::Strict::Bool,
          decimal: Types::Strict::Decimal,
          blob: Types::Strict::String
        ).freeze

        pk_type Types::Serial

        attr_reader :dsl

        def initialize(dsl)
          @dsl = dsl
        end

        def call(dataset, gateway)
          columns = gateway.connection.schema(dataset)

          columns.each do |(name, definition)|
            dsl.attribute name, build_type(definition)
          end

          pks = columns.select { |(name, definition)| definition.fetch(:primary_key) }.map(&:first)

          dsl.primary_key *pks if pks.any?
          dsl.attributes
        end

        def build_type(definition)
          if definition.fetch(:primary_key)
            self.class.pk_type
          else
            type = self.class.type_mapping.fetch(definition.fetch(:type))
            type = type.optional if definition.fetch(:allow_null)
            type
          end
        end
      end

      class AssociateDSL < BasicObject
        attr_reader :source, :associations

        def initialize(source, &block)
          @source = source
          @associations = {}
          instance_exec(&block)
        end

        def many(target, options = {})
          if options[:through]
            association = Association::ManyToMany.new(source, target, options)
          else
            association = Association::OneToMany.new(source, target, options)
          end

          @associations[association.name] = association
        end

        def one(target, options = {})
          if options[:through]
            association = Association::OneToOneThrough.new(source, target, options)
          else
            association = Association::OneToOne.new(source, target, options)
          end

          @associations[association.name] = association
        end

        def belongs(target, options = {})
          association = Association::ManyToOne.new(source, target, options)
          @associations[association.name] = association
        end

        def call
          associations
        end
      end

      class DSL < ROM::Schema::DSL
        attr_reader :associations

        def associate(&block)
          @associations = AssociateDSL.new(name, &block)
        end

        def call
          SQL::Schema.new(name,
                          attributes,
                          associations && associations.call,
                          inferrer: inferrer && inferrer.new(self))
        end
      end

      def initialize(name, attributes, associations = nil, inferrer: nil)
        @associations = associations
        super(name, attributes, inferrer: inferrer)
      end
    end
  end
end
