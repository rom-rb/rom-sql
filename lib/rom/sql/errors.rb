require "rom/sql/error"

module ROM
  module SQL
    NoAssociationError        = Class.new(StandardError)
    DatabaseError             = Class.new(Error)
    ConstraintError           = Class.new(Error)
    NotNullConstraintError    = Class.new(ConstraintError)
    UniqueConstraintError     = Class.new(ConstraintError)
    ForeignKeyConstraintError = Class.new(ConstraintError)
    CheckConstraintError      = Class.new(ConstraintError)

    ERROR_MAP = {
      Sequel::DatabaseError => DatabaseError,
      Sequel::NotNullConstraintViolation => NotNullConstraintError,
      Sequel::UniqueConstraintViolation => UniqueConstraintError,
      Sequel::ForeignKeyConstraintViolation => ForeignKeyConstraintError,
      Sequel::CheckConstraintViolation => CheckConstraintError
    }.freeze
  end
end
