require 'bundler'
Bundler.setup

if ENV['COVERAGE'] == 'true'
  require 'codacy-coverage'
  Codacy::Reporter.start
end

require 'warning'

Warning.ignore(/\$SAFE/)
Warning.ignore(/sequel/)
Warning.ignore(/mysql2/)
Warning.ignore(/rspec-core/)
Warning.ignore(/__FILE__/)
Warning.ignore(/__LINE__/)
Warning.process { |w| raise RuntimeError, w } if ENV['FAIL_ON_WARNINGS'].eql?('true')

require 'rom-sql'
require 'rom/sql/rake_task'

require 'logger'
require 'tempfile'

begin
  require ENV['DEBUGGER'] || 'byebug'
rescue LoadError
  require 'pry'
end

LOGGER = Logger.new(File.open('./log/test.log', 'a'))
ENV['TZ'] ||= 'UTC'

oracle_settings = {
  db_name: ENV.fetch('ROM_ORACLE_DATABASE', 'xe'),
  host: ENV.fetch('ROM_ORACLE_HOST', 'localhost'),
  port: Integer(ENV.fetch('ROM_ORACLE_PORT', '1521'))
}

if defined? JRUBY_VERSION
  DB_URIS = {
    sqlite: 'jdbc:sqlite:',
    postgres: ENV.fetch('POSTGRES_DSN', 'jdbc:postgresql://localhost/rom_sql'),
    mysql: ENV.fetch('MYSQL_DSN', 'jdbc:mysql://localhost/rom_sql?user=root&sql_mode=STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION&useSSL=false'),
    oracle: ENV['ROM_USE_ORACLE'] ? fail('Setup Oracle for JRuby!') : nil
  }
else
  DB_URIS = {
    sqlite: 'sqlite::memory',
    postgres: ENV.fetch('POSTGRES_DSN', 'postgres://localhost/rom_sql'),
    mysql: ENV.fetch('MYSQL_DSN', 'mysql2://root@localhost/rom_sql?sql_mode=STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION'),
    oracle: "oracle://#{ oracle_settings[:host] }:#{ oracle_settings[:port] }/" \
            "#{ oracle_settings[:db_name] }?username=rom_sql&password=rom_sql&autosequence=true"
  }
end

ADAPTERS = ENV['ROM_USE_ORACLE'] ? DB_URIS.keys : DB_URIS.keys - %i(oracle)
PG_LTE_95 = ENV.fetch('PG_LTE_95', 'true') == 'true'

SPEC_ROOT = root = Pathname(__FILE__).dirname

TMP_PATH = root.join('../tmp')

# quiet in specs
ROM::SQL::Relation.tap { |r| r.schema_inferrer(r.schema_inferrer.suppress_errors) }

require 'dry/core/deprecations'
Dry::Core::Deprecations.set_logger!(root.join('../log/deprecations.log'))

ROM::SQL.load_extensions(:postgres, :sqlite)

require 'dry-types'
module Types
  include Dry::Types.module
end

def with_adapters(*args, &block)
  reset_adapter = Hash[*ADAPTERS.flat_map { |a| [a, false] }]
  adapters = args.empty? || args[0] == :all ? ADAPTERS : (args & ADAPTERS)

  adapters.each do |adapter|
    context("with #{adapter}", **reset_adapter, adapter => true, &block)
  end
end

RSpec.configure do |config|
  config.disable_monkey_patching!
  config.warnings = true
  config.filter_run_when_matching :focus

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

  Dir[root.join('shared/**/*.rb')].each { |f| require f }
  Dir[root.join('support/**/*.rb')].each { |f| require f }

  config.include(Helpers, helpers: true)
  config.include ENVHelper
end
