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

end
