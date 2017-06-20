require 'rom/configuration'

class TestConfiguration < ROM::Configuration
  def relation(name, &block)
    if registered_relation_names.include?(name)
      setup.relation_classes.delete_if do |klass|
        klass.schema.name.relation == name
      end
    end
    super
  end

  def registered_relation_names
    setup.relation_classes.map(&:schema).map(&:name).map(&:relation)
  end
end
