require 'rom/sql/commands'

module ROM
  module SQL
    module Commands
      class Create < ROM::Commands::Create
        include TupleCount

        def self.build(relation, options = {})
          case relation.db.database_type
          when :postgres
            Postgres::Create.new(relation, self.options.merge(options))
          else
            super
          end
        end

        def execute(tuples)
          insert_tuples = Array([tuples]).flatten.map do |tuple|
            attributes = input[tuple]
            validator.call(attributes)
            attributes
          end

          insert(insert_tuples)
        rescue *ERRORS => e
          raise ConstraintError, e.message
        end

        def insert(tuples)
          pks = tuples.map { |tuple| relation.insert(tuple) }
          relation.where(relation.model.primary_key => pks)
        end
      end
    end
  end
end
