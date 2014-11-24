class Sequel::Dataset

  def header
    ROM::SQL::Header.new(opts.fetch(:select) { columns }, opts[:from].first)
  end

  def project(*names)
    select(*header.project(*names))
  end

  def rename(options)
    select(*header.rename(options))
  end

  def prefix(col_prefix = default_prefix)
    rename(header.prefix(col_prefix).to_h)
  end

  def qualified
    select(*qualified_columns)
  end

  def qualified_columns
    header.qualified.to_a
  end

  private

  def default_prefix
    Inflecto.singularize(opts[:from].first)
  end

end
