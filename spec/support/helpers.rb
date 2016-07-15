module Helpers
  def qualified_attribute(*args)
    ROM::SQL::QualifiedAttribute[*args]
  end

  def assoc_name(*args)
    ROM::SQL::Association::Name[*args]
  end
end
