require 'rom/configuration'

class TestConfiguration < ROM::Configuration
  def relation(name, *, &block)
    if registered_relation_names.include?(name)
      setup.relation_classes.delete_if do |klass|
        klass.relation_name.relation == name
      end
    end
    super
  end

  def registered_relation_names
    setup.relation_classes.map(&:relation_name).map(&:relation)
  end
end
