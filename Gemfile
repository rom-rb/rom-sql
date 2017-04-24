source 'https://rubygems.org'

gemspec

gem 'rom', git: 'https://github.com/rom-rb/rom.git', branch: 'use-initializer-in-attribute'
gem 'rom-mapper', git: 'https://github.com/rom-rb/rom-mapper.git', branch: 'master'
gem 'dry-types', git: 'https://github.com/dry-rb/dry-types.git', branch: 'master'

group :test do
  gem 'byebug', platforms: :mri
  gem 'pry', platforms: %i(jruby rbx)
  gem 'dry-struct'
  gem 'activesupport', '~> 5.0'
  gem 'codeclimate-test-reporter', require: false
  gem 'simplecov', require: false

  if RUBY_ENGINE == 'rbx'
    gem 'pg', '~> 0.18.0', platforms: :rbx
  else
    gem 'pg', '~> 0.19', platforms: :mri
  end

  gem 'mysql2', platforms: [:mri, :rbx]
  gem 'jdbc-postgres', platforms: :jruby
  gem 'jdbc-mysql', platforms: :jruby
  gem 'sqlite3', platforms: [:mri, :rbx]
  gem 'jdbc-sqlite3', platforms: :jruby
  gem 'ruby-oci8', platforms: :mri if ENV['ROM_USE_ORACLE']
end

group :tools do
  gem 'rom-repository', git: 'https://github.com/rom-rb/rom-repository.git', branch: 'master'
end
