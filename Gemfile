source 'https://rubygems.org'

gemspec

group :test do
  gem 'rom', '~> 0.6.0', github: 'rom-rb/rom', branch: 'master'
  gem 'minitest'
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
