module ROM
  module SQL
    module Commands
      module ErrorWrapper
        def call(*args)
          super
        rescue Sequel::CheckConstraintViolation => e
          raise CheckConstraintError, e.message
        rescue *ERRORS => e
          raise ConstraintError, e.message
        rescue Sequel::DatabaseError => e
          raise DatabaseError, e.message
        end
      end
    end
  end
end
