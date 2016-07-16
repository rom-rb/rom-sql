# encoding: utf-8

require 'bundler'
Bundler.setup

if RUBY_ENGINE == 'rbx'
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
  SQLITE_DB_URI = 'jdbc:sqlite::memory'
  POSTGRES_DB_URI = 'jdbc:postgresql://localhost/rom_sql'
else
  SQLITE_DB_URI = 'sqlite::memory'
  POSTGRES_DB_URI = 'postgres://localhost/rom_sql'
  MYSQL_DB_URI = 'mysql2://root@localhost/rom_sql'
end

URIS = { postgres: POSTGRES_DB_URI, sqlite: SQLITE_DB_URI, mysql: MYSQL_DB_URI }

root = Pathname(__FILE__).dirname
TMP_PATH = root.join('../tmp')

Dir[root.join('shared/**/*')].each { |f| require f }
Dir[root.join('support/**/*')].each { |f| require f }

require 'rom/support/deprecations'
ROM::Deprecations.set_logger!(root.join('../log/deprecations.log'))

RSpec.configure do |config|
  config.before(:suite) do
    tmp_test_dir = TMP_PATH.join('test')
    FileUtils.rm_r(tmp_test_dir) if File.exist?(tmp_test_dir)
    FileUtils.mkdir_p(tmp_test_dir)
  end

  config.around(adapter: :mysql) do |example|
    Object.const_set(:DB_URI, URIS[:mysql])
    example.run
    Object.send(:remove_const, :DB_URI)
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
