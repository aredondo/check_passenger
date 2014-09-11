# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'check_passenger/version'

Gem::Specification.new do |spec|
  spec.name          = 'check_passenger'
  spec.version       = CheckPassenger::VERSION
  spec.authors       = ['Alvaro Redondo']
  spec.email         = ['alvaro@redondo.name']
  spec.summary       = %q{Check status and memory of Passenger processes.}
  # spec.description   = %q{TODO: Write a longer description. Optional.}
  spec.homepage      = ''
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.6'
end
