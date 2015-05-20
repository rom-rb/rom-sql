module ROM
  module SQL
    module Commands
      module ErrorWrapper
        def call(*args)
          super
        rescue Sequel::NotNullConstraintViolation => e
          raise NotNullConstraintError, e.message
        rescue Sequel::UniqueConstraintViolation => e
          raise UniqueConstraintError, e.message
        rescue Sequel::CheckConstraintViolation => e
          raise CheckConstraintError, e.message
        rescue Sequel::ForeignKeyConstraintViolation => e
          raise ForeignKeyConstraintError, e.message
        rescue Sequel::DatabaseError => e
          raise DatabaseError, e.message
        end
      end
    end
  end
end
