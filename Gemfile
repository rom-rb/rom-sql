source 'https://rubygems.org'

gemspec

group :test do
  gem 'codacy-coverage', require: false
  gem 'pry-byebug', platforms: :mri
  gem 'pry', platforms: :jruby
  gem 'activesupport', '~> 5.0'
  gem 'simplecov', require: false
  gem 'pg', '~> 1.1', platforms: :mri
  gem 'mysql2', platforms: :mri
  gem 'jdbc-postgres', '>= 9.4.1212', platforms: :jruby
  gem 'jdbc-mysql', platforms: :jruby
  gem 'sqlite3', platforms: :mri
  gem 'jdbc-sqlite3', platforms: :jruby
  gem 'ruby-oci8', platforms: :mri if ENV['ROM_USE_ORACLE']
  gem 'warning'
end
