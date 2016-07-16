# encoding: utf-8

require 'bundler'
Bundler.setup

if RUBY_ENGINE == 'ruby' && RUBY_VERSION == '2.3.1'
  require 'codeclimate-test-reporter'
  CodeClimate::TestReporter.start
end

require 'rom-sql'
require 'rom/sql/rake_task'

require 'logger'
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

URIS = { postgres: POSTGRES_DB_URI, sqlite: SQLITE_DB_URI, mysql: MYSQL_DB_URI }
ADAPTERS = URIS.keys

root = Pathname(__FILE__).dirname
TMP_PATH = root.join('../tmp')

Dir[root.join('shared/**/*')].each { |f| require f }
Dir[root.join('support/**/*')].each { |f| require f }

require 'rom/support/deprecations'
ROM::Deprecations.set_logger!(root.join('../log/deprecations.log'))

def db?(type, example = nil)
  if example
    example.metadata[:adapter] == type
  else
    defined?(DB_URI) && DB_URI.include?(type.to_s)
  end
end

def postgres?(example = nil)
  db?(:postgres, example)
end

def mysql?(example = nil)
  db?(:mysql, example)
end

def with_adapter(adapter, &block)
  Object.const_set(:DB_URI, URIS[:mysql])
  block.call
  Object.send(:remove_const, :DB_URI)
end

def with_adapters(*args, &block)
  adapters = args.empty? || args[0] == :all ? ADAPTERS : args

  adapters.each do |adapter|
    context("with #{adapter}", adapter: adapter, &block)
  end
end

RSpec.configure do |config|
  config.disable_monkey_patching

  config.before(:suite) do
    tmp_test_dir = TMP_PATH.join('test')
    FileUtils.rm_r(tmp_test_dir) if File.exist?(tmp_test_dir)
    FileUtils.mkdir_p(tmp_test_dir)
  end

  config.around(adapter: :mysql) do |example|
    with_adapter(:mysql) { example.run }
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
