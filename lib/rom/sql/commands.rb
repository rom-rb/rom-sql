module Commands
  ERRORS = [
    Sequel::UniqueConstraintViolation,
    Sequel::NotNullConstraintViolation
  ].freeze

  class Create
    include Concord.new(:relation, :input, :validator)

    def self.build(relation, definition)
      new(relation, definition.input, definition.validator)
    end

    def execute(tuple)
      attributes = input[tuple]

      validation = validator.call(attributes)

      if validation.success?
        begin
          pk = relation.insert(attributes.to_h)
          relation.where(relation.model.primary_key => pk).first
        rescue *ERRORS => e
          validation.errors << e.message
          validation
        end
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
        pks = relation.map { |t| t[relation.model.primary_key] }
        relation.update(attributes.to_h)
        relation.unfiltered.where(relation.model.primary_key => pks)
      else
        validation
      end
    end

    def new(*args, &block)
      self.class.new(relation.public_send(*args, &block), input, validator)
    end
  end

end
