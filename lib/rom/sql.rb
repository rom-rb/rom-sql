require "sequel"

class Sequel::Dataset
  alias_method :header, :columns

  def rename(options)
    columns = header - options.keys
    options.each { |old, new| columns << :"#{name}__#{old}___#{new}" }

    select(*columns)
  end

  def prefix(col_prefix)
    rename(Hash[header.map { |col| [col, "#{col_prefix}_#{col}"] }])
  end

  def name
    opts[:from].first
  end
end

require "rom"
require "rom/sql/version"
require "rom/sql/relation_extension"
require "rom/sql/relation_inclusion"
require "rom/sql/adapter"
