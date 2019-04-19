source 'https://rubygems.org'

git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }

gemspec

gem 'dry-equalizer', github: 'dry-rb/dry-equalizer', branch: 'master'
gem 'dry-struct', github: 'dry-rb/dry-struct', branch: 'master'
gem 'dry-logic', github: 'dry-rb/dry-logic', branch: 'master'
gem 'dry-types', github: 'dry-rb/dry-types', branch: 'master'

gem 'rom', github: 'rom-rb/rom', branch: 'master' do
  gem 'rom-core'
  gem 'rom-mapper'
  gem 'rom-repository', group: :tools
end

group :test do
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
