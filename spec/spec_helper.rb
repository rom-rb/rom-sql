require_relative 'support/coverage'

require 'warning'

Warning.ignore(/\$SAFE/)
Warning.ignore(/sequel/)
Warning.ignore(/mysql2/)
Warning.ignore(/rake/)
Warning.ignore(/rspec-core/)
Warning.ignore(/__FILE__/)
Warning.ignore(/__LINE__/)
Warning.ignore(/codacy/)
Warning.ignore(/dry\/core\/equalizer/)
Warning.ignore(/dry\/equalizer/)
Warning.process { |w| raise RuntimeError, w } if ENV['FAIL_ON_WARNINGS'].eql?('true')

require 'fileutils'

is_jruby = defined?(JRUBY_VERSION)

unless File.exist?('.env')
  env_file = is_jruby ? '.env.jdbc' : '.env.default'
  puts "Copying #{env_file} => .env"
  FileUtils.cp(env_file, '.env')
end

require 'dotenv/load'

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

DB_URIS = {
  sqlite: is_jruby ? 'jdbc:sqlite:' : 'sqlite::memory',
  postgres: ENV['POSTGRES_DSN'],
  mysql: ENV['MYSQL_DSN']
}

if (oracle_dsn = ENV['ORACLE_DSN'])
  DB_URIS[:oracle] = oracle_dsn
end

require 'pp'

puts "\n"
puts "*"*80
puts "\n"
puts "Running tests with the following database config:\n"
puts "\n"
pp DB_URIS
puts "\n"
puts "*"*80
puts "\n"

puts "Connections check...\n\n"

conn_test = DB_URIS.map do |type, uri|
  result =
    begin
      [Sequel.connect(uri).test_connection]
    rescue => e
      [false, e.message]
    end

  is_ok, err = result

  if is_ok
    puts "[#{type}] success!"
  else
    puts "[#{type}] failure! Error: #{err}"
  end

  is_ok
end

puts "\n"

if conn_test.all?
  puts "All connections successful"
else
  puts "Some connections failed. Make sure you started database containers via `docker-compose up`!"
  puts "*"*80
  puts "\n"

  exit(1)
end

ADAPTERS = DB_URIS.keys
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
  include Dry.Types(default: :strict)
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
