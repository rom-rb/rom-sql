module Helpers
  def assoc_name(*args)
    ROM::Relation::Name[*args]
  end

  def define_schema(name, attrs = [])
    relation_name = ROM::Relation::Name.new(name)
    ROM::SQL::Schema.define(
      relation_name,
      attributes: attrs.map { |key, value| value.meta(name: key, source: relation_name) },
      attr_class: ROM::SQL::Attribute
    )
  end

  def define_attribute(name, id, **opts)
    ROM::SQL::Attribute.new(ROM::Types.const_get(id).meta(name: name, **opts))
  end

  def build_assoc(type, *args)
    klass = Dry::Core::Inflector.classify(type)
    definition = ROM::Associations::Definitions.const_get(klass).new(*args)
    ROM::SQL::Associations.const_get(definition.type).new(definition, relations)
  end
end
