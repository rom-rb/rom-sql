require 'bundler'
Bundler.setup

if RUBY_ENGINE == 'ruby' && RUBY_VERSION == '2.3.1'
  require 'codeclimate-test-reporter'
  CodeClimate::TestReporter.start
end

require 'rom-sql'
require 'rom/sql/rake_task'

require 'logger'
require 'tempfile'

begin
  require 'byebug'
rescue LoadError # rubocop:disable Lint/HandleExceptions
end

LOGGER = Logger.new(File.open('./log/test.log', 'a'))

if defined? JRUBY_VERSION
  SQLITE_DB_URI = 'jdbc:sqlite:::memory'
  POSTGRES_DB_URI = 'jdbc:postgresql://localhost/rom_sql'
  MYSQL_DB_URI = 'jdbc:mysql://localhost/rom_sql?user=root'
else
  SQLITE_DB_URI = 'sqlite::memory'
  POSTGRES_DB_URI = 'postgres://localhost/rom_sql'
  MYSQL_DB_URI = 'mysql2://root@localhost/rom_sql'
end

DB_URIS = { postgres: POSTGRES_DB_URI, sqlite: SQLITE_DB_URI, mysql: MYSQL_DB_URI }
ADAPTERS = DB_URIS.keys
PG_LTE_95 = ENV.fetch('PG_LTE_95', 'true') == 'true'

SPEC_ROOT = root = Pathname(__FILE__).dirname
TMP_PATH = root.join('../tmp')

Dir[root.join('shared/**/*')].each { |f| require f }
Dir[root.join('support/**/*')].each { |f| require f }

require 'rom/support/deprecations'
ROM::Deprecations.set_logger!(root.join('../log/deprecations.log'))

module DBHelper
  def db?(type, example)
    example.metadata[:adapter] == type
  end

  def postgres?(example)
    db?(:postgres, example)
  end

  def mysql?(example)
    db?(:mysql, example)
  end

  def sqlite?(example)
    db?(:sqlite, example)
  end
end

def with_adapters(*args, &block)
  adapters = args.empty? || args[0] == :all ? ADAPTERS : args

  adapters.each do |adapter|
    context("with #{adapter}", context_adapter: adapter, &block)
  end
end

RSpec.configure do |config|
  config.disable_monkey_patching!

  config.include DBHelper

  config.before(:suite) do
    tmp_test_dir = TMP_PATH.join('test')
    FileUtils.rm_r(tmp_test_dir) if File.exist?(tmp_test_dir)
    FileUtils.mkdir_p(tmp_test_dir)
  end

  config.around do |example|
    specific_adapters = example.metadata[:adapter]
    context_adapter = example.metadata[:context_adapter]

    if specific_adapters && context_adapter
      if Array(specific_adapters).include?(context_adapter)
        example.run
      else
        # noop
      end
    elsif !specific_adapters
      example.metadata[:adapter] = context_adapter || :postgres
      example.run
    else
      example.run
    end
  end

  config.before do
    module Test
    end
  end

  config.after do
    Object.send(:remove_const, :Test)
  end

  config.include(Helpers, helpers: true)
end
