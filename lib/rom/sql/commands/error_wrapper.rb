module ROM
  module SQL
    module Commands
      module ErrorWrapper
        def execute(*args)
          super
        rescue *ERRORS => e
          raise ConstraintError, e.message
        rescue Sequel::DatabaseError => e
          raise ROM::SQL::DatabaseError.new(e, e.message)
        end
      end
    end
  end
end