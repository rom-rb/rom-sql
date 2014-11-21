require "sequel"

class Sequel::Dataset
  alias_method :header, :columns
end

require "rom"
require "rom/sql/version"
require "rom/sql/relation_extension"
require "rom/sql/relation_inclusion"
require "rom/sql/adapter"
