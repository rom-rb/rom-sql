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
  DB_URIS = {
    sqlite: 'jdbc:sqlite:::memory',
    postgres: 'jdbc:postgresql://localhost/rom_sql',
    mysql: 'jdbc:mysql://localhost/rom_sql?user=root'
  }
else
  DB_URIS = {
    sqlite: 'sqlite::memory',
    postgres: 'postgres://localhost/rom_sql',
    mysql: 'mysql2://root@localhost/rom_sql'
  }
end

ADAPTERS = DB_URIS.keys
PG_LTE_95 = ENV.fetch('PG_LTE_95', 'true') == 'true'

SPEC_ROOT = root = Pathname(__FILE__).dirname
TMP_PATH = root.join('../tmp')

Dir[root.join('shared/**/*')].each { |f| require f }
Dir[root.join('support/**/*')].each { |f| require f }

require 'rom/support/deprecations'
ROM::Deprecations.set_logger!(root.join('../log/deprecations.log'))

module ENVHelper
  def db?(type, example)
    example.metadata[type]
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

  def jruby?
    defined? JRUBY_VERSION
  end
end

def with_adapters(*args, &block)
  reset_adapter = { postgres: false, mysql: false, sqlite: false }
  adapters = args.empty? || args[0] == :all ? ADAPTERS : args

  adapters.each do |adapter|
    context("with #{adapter}", **reset_adapter, adapter => true, &block)
  end
end

RSpec.configure do |config|
  config.disable_monkey_patching!

  config.include ENVHelper

  config.before(:suite) do
    tmp_test_dir = TMP_PATH.join('test')
    FileUtils.rm_r(tmp_test_dir) if File.exist?(tmp_test_dir)
    FileUtils.mkdir_p(tmp_test_dir)
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
