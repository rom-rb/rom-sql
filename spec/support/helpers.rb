# frozen_string_literal: true

module Helpers
  def assoc_name(*args)
    ROM::Relation::Name[*args]
  end

  def define_schema(name, attrs = [])
    relation_name = ROM::Relation::Name.new(name)
    ROM::SQL::Schema.define(
      relation_name,
      attributes: attrs.map do |attr_name, type|
        ROM::SQL::Schema.build_attribute_info(
          type.meta(source: relation_name),
          name: attr_name
        )
      end,
      attr_class: ROM::SQL::Attribute
    )
  end

  def define_attribute(name, id, **opts)
    type = id.is_a?(Symbol) ? ROM::Types.const_get(id) : id
    ROM::SQL::Attribute.new(type.meta(opts), name: name)
  end

  def build_assoc(type, *args)
    klass = ROM::Inflector.classify(type)
    definition = ROM::Associations::Definitions.const_get(klass).new(*args)
    ROM::SQL::Associations.const_get(definition.type).new(definition, relations)
  end
  ruby2_keywords(:build_assoc) if respond_to?(:ruby2_keywords, true)

  def attributes(schema)
    schema.each_with_object({}) do |(key, type), acc|
      type = type.type if type.is_a?(ROM::SQL::Attribute)

      if type.optional?
        attr = ROM::SQL::Attribute.new(type.right, name: key).optional
      else
        attr = ROM::SQL::Attribute.new(type, name: key)
      end

      acc[key] = attr.meta(source: source)
    end
  end
end
