source 'https://rubygems.org'

gemspec

gem 'dry-struct',     require: false, github: 'dry-rb/dry-struct'     # FIXME: this is needed until they will release 0.1
gem 'dry-types',      require: false, github: 'dry-rb/dry-types'      # FIXME: this is needed until they will release 0.9
gem 'dry-validation', require: false, github: 'dry-rb/dry-validation' # FIXME: this is needed until they will release 0.10

group :test do
  gem 'byebug', platforms: :mri
  gem 'anima', '~> 0.2.0'
  gem 'virtus'
  gem 'activesupport', '~> 4.2'
  gem 'rspec', '~> 3.1'
  gem 'codeclimate-test-reporter', require: false
  gem 'pg', platforms: [:mri, :rbx]
  gem 'mysql2', platforms: [:mri, :rbx]
  gem 'jdbc-postgres', platforms: :jruby
  gem 'jdbc-mysql', platforms: :jruby
  gem 'sqlite3', platforms: [:mri, :rbx]
  gem 'jdbc-sqlite3', platforms: :jruby
end
