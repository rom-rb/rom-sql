require "rom/setup"

class TestConfiguration < ROM::Setup
  def relation(name, **opts, &block)
    if components.relations.map(&:id).include?(name)
      components.relations.delete_if do |component|
        component.id == name
      end

      components.schemas.delete_if do |component|
        component.id == name
      end
    end

    super(name, **opts, &block)
  end

  def gateways
    registry.gateways
  end
end
