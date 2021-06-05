source 'https://rubygems.org'

gemspec

eval_gemfile 'Gemfile.devtools'

gem 'rom', git: 'https://github.com/rom-rb/rom.git', branch: 'master'

if ENV['DRY_TYPES_FROM_MASTER'].eql?('true')
  gem 'dry-types', git: 'https://github.com/dry-rb/dry-types.git', branch: 'master'
end

if ENV['SEQUEL_FROM_MASTER'].eql?('true')
  gem 'sequel', git: 'https://github.com/jeremyevans/sequel.git', branch: 'master'
else
  gem 'sequel', '5.31.0'
end

group :test do
  gem 'pry-byebug', platforms: :ruby
  gem 'pry', platforms: :jruby
  gem 'activesupport', '~> 5.0'
  gem 'pg', '~> 1.2', platforms: :ruby
  gem 'mysql2', '~> 0.5', platforms: :ruby
  gem 'jdbc-postgres', '>= 9.4.1212', platforms: :jruby
  gem 'jdbc-mysql', platforms: :jruby
  gem 'sqlite3', '~> 1.4', platforms: :ruby
  gem 'jdbc-sqlite3', platforms: :jruby
  gem 'ruby-oci8', platforms: :ruby if ENV['ROM_USE_ORACLE']
  gem 'dotenv', require: false
  gem 'sequel_pg', require: false, platforms: :ruby
end
