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
    type = id.is_a?(Symbol) ? ROM::Types.const_get(id) : id
    ROM::SQL::Attribute.new(type.meta(name: name, **opts))
  end

  def build_assoc(type, *args)
    klass = ROM::Inflector.classify(type)
    definition = ROM::Associations::Definitions.const_get(klass).new(*args)
    ROM::SQL::Associations.const_get(definition.type).new(definition, relations)
  end

  def attributes(schema)
    schema.each_with_object({}) do |(key, type), acc|
      if type.optional?
        attr = ROM::SQL::Attribute.new(type.right).optional
      else
        attr = ROM::SQL::Attribute.new(type)
      end

      meta = { name: key, source: source }

      acc[key] = attr.meta(meta)
    end
  end
end
