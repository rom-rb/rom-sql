source 'https://rubygems.org'

gemspec

group :test do
  gem 'rom', git: 'https://github.com/rom-rb/rom.git', branch: 'boot-with-finalize'
  gem 'rspec', '~> 3.1'
  gem 'codeclimate-test-reporter', require: false
  gem 'sqlite3', platforms: [:mri, :rbx]
  gem 'jdbc-sqlite3', platforms: :jruby
end
