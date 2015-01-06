require 'rom-sql'
require 'rom/adapter/lint/test'

require 'minitest/autorun'

class MemoryAdapterLintTest < MiniTest::Test
  include ROM::Adapter::Lint::TestAdapter

  def setup
    @adapter = ROM::SQL::Adapter
    @uri = "postgres://localhost/rom"
  end
end
