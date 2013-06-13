# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'envy'

Gem::Specification.new do |spec|
  spec.name          = 'envy'
  spec.version       = Envy::VERSION
  spec.authors       = ['Arjan van der Gaag']
  spec.email         = ['arjan@arjanvandergaag.nl']
  spec.description   = %q{Configure required environment variables in your Rails apps}
  spec.summary       = <<-EOS
  Envy is a simple tool to make managing required environment variables for
  your Rails application a little easier. It allows you to define the required
  variables in a YAML file and provide sensible failure instructions.
  EOS
  spec.homepage      = 'https://github.com/avdgaag/envy'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'yard'
  spec.add_development_dependency 'rspec', '>= 2.13'
end
