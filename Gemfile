source 'https://rubygems.org'

git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }

if ENV['USE_SEQUEL_MASTER'] == 'true'
  gem 'sequel', github: 'jeremyevans/sequel'
end

if ENV['USE_ROM_MASTER'] == 'true'
  gem 'rom-core', github: 'rom-rb/rom'
end

gem 'dry-types', github: 'dry-rb/dry-types', branch: 'master'

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
end
