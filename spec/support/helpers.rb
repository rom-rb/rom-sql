module Helpers
  def qualified_name(*args)
    ROM::SQL::QualifiedName[*args]
  end
end
