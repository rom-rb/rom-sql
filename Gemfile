source 'https://rubygems.org'

gemspec

gem 'rom', git: 'https://github.com/rom-rb/rom.git', branch: 'master'
gem 'rom-support', git: 'https://github.com/rom-rb/rom-support.git', branch: 'master'

group :test do
  gem 'byebug', platforms: :mri
  gem 'dry-struct'
  gem 'activesupport', '~> 4.2'
  gem 'rspec', '~> 3.1'
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
end
