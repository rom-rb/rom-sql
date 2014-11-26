module Commands

  class Create
    include Concord.new(:relation, :input, :validator)

    def self.build(relation, definition)
      new(relation, definition.input, definition.validator)
    end

    def execute(tuple)
      attributes = input[tuple]

      validation = validator.call(attributes)

      if validation.success?
        id = relation.insert(attributes.to_h)
        relation.where(id: id).first
      else
        validation
      end
    end
  end

  class Update
    include Concord.new(:relation, :input, :validator)

    def self.build(relation, definition)
      new(relation, definition.input, definition.validator)
    end

    def execute(tuple)
      attributes = input[tuple]

      validation = validator.call(attributes)

      if validation.success?
        ids = relation.map { |tuple| tuple[:id] }
        relation.update(attributes.to_h)
        relation.unfiltered.where(id: ids)
      else
        validation
      end
    end

    def new(*args, &block)
      self.class.new(relation.public_send(*args, &block), input, validator)
    end
  end

end
