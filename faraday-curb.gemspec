# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'faraday/curb/version'

Gem::Specification.new do |spec|
  spec.name          = "faraday-curb"
  spec.version       = Faraday::Curb::VERSION
  spec.authors       = ["Aaron Eisenberger"]
  spec.email         = ["aaron@bitium.com"]
  spec.summary       = %q{A Curb adapter for Faraday.}
  spec.description   = %q{Ever wanted to use Faraday with Curb? Now you can.}
  spec.homepage      = "https://github.com/bitium/faraday-curb"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "curb", '~> 0'
  spec.add_dependency "faraday", '~> 0'

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
end
