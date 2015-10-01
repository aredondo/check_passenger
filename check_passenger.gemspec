# coding: utf-8

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'check_passenger/version'

Gem::Specification.new do |spec|
  spec.name          = 'check_passenger'
  spec.version       = CheckPassenger::VERSION
  spec.authors       = ['Alvaro Redondo']
  spec.email         = ['alvaro@redondo.name']
  spec.summary       = 'Nagios check to monitor Passenger processes and memory'
  # spec.description   = %q{TODO: Write a longer description. Optional.}
  spec.homepage      = 'https://github.com/aredondo/check_passenger'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.6'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'minitest'
  spec.add_development_dependency 'minitest-reporters'

  spec.add_dependency 'thor', '~> 0.19.1'
end
