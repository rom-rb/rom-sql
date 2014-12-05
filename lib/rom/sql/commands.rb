module ROM
  module SQL
    module Commands
      ERRORS = [
        Sequel::UniqueConstraintViolation,
        Sequel::NotNullConstraintViolation
      ].freeze

      class Create < ROM::Commands::Create

        def execute(tuple)
          attributes = input[tuple]
          validator.call(attributes)

          pk = relation.insert(attributes.to_h)

          relation.where(relation.model.primary_key => pk)
        rescue *ERRORS => e
          raise ConstraintError, e.message
        end
      end

      class Update < ROM::Commands::Update

        def execute(tuple)
          attributes = input[tuple]
          validator.call(attributes)

          pks = relation.map { |t| t[relation.model.primary_key] }

          relation.update(attributes.to_h)
          relation.unfiltered.where(relation.model.primary_key => pks)
        end

      end

      class Delete < ROM::Commands::Delete

        def execute
          target.delete
          relation
        end

      end

    end
  end
end
