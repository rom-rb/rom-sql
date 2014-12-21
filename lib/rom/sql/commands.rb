module ROM
  module SQL
    module Commands
      ERRORS = [
        Sequel::UniqueConstraintViolation,
        Sequel::NotNullConstraintViolation
      ].freeze

      class Create < ROM::Commands::Create
        def execute(tuples)
          pks = Array([tuples]).flatten.map do |tuple|
            attributes = input[tuple]
            validator.call(attributes)
            relation.insert(attributes.to_h)
          end

          relation.where(relation.model.primary_key => pks)
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
          deleted = target.to_a
          target.delete
          deleted
        end
      end

    end
  end
end
