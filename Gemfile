source 'https://rubygems.org'

gemspec

group :test do
  gem 'byebug', platforms: :mri
  gem 'rom', github: 'rom-rb/rom', branch: 'master'
  gem 'virtus'
  gem 'activesupport'
  gem 'rspec', '~> 3.1'
  gem 'codeclimate-test-reporter', require: false
  gem 'pg', platforms: [:mri, :rbx]
  gem 'pg_jruby', platforms: :jruby
end

group :tools do
  gem 'guard'
  gem 'guard-rspec'
  gem 'guard-rubocop'
  gem 'rubocop', '~> 0.28'
end
