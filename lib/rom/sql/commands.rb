module ROM
  module SQL
    module Commands
      ERRORS = [
        Sequel::UniqueConstraintViolation,
        Sequel::NotNullConstraintViolation
      ].freeze

      module TupleCount
        # TODO: we need an interface for "target_count" here
        def assert_tuple_count
          if result == :one && target.count > 1
            raise TupleCountMismatchError, "#{inspect} expects one tuple"
          end
        end
      end

      module Create
        include ROM::Commands::Create
        include TupleCount

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

      module Update
        include ROM::Commands::Update
        include TupleCount

        def execute(tuple)
          attributes = input[tuple]
          validator.call(attributes)

          pks = relation.map { |t| t[relation.model.primary_key] }

          relation.update(attributes.to_h)
          relation.unfiltered.where(relation.model.primary_key => pks)
        end
      end

      module Delete
        include ROM::Commands::Delete
        include TupleCount

        def execute
          deleted = target.to_a
          target.delete
          deleted
        end
      end
    end
  end
end
