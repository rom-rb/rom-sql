lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rom/sql/version'

Gem::Specification.new do |spec|
  spec.name          = 'rom-sql'
  spec.version       = ROM::SQL::VERSION.dup
  spec.authors       = ['Piotr Solnica']
  spec.email         = ['piotr.solnica@gmail.com']
  spec.summary       = 'SQL databases support for ROM'
  spec.description   = spec.summary
  spec.homepage      = 'http://rom-rb.org'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'sequel', '~> 4.43'
  spec.add_runtime_dependency 'dry-equalizer', '~> 0.2'
  spec.add_runtime_dependency 'dry-types', '~> 0.11.0'
  spec.add_runtime_dependency 'dry-core', '~> 0.3'
  spec.add_runtime_dependency 'rom', '~> 3.2', '>= 3.2.2'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.5'
end
