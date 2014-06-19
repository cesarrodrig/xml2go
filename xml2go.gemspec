# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'xml2go/version'

Gem::Specification.new do |spec|
  spec.name          = "xml2go"
  spec.version       = Xml2go::VERSION
  spec.authors       = ["Cesar Rodriguez"]
  spec.email         = ["cesar@ooyala.com"]
  spec.summary       = %q{Convert XML to Go structs}
  spec.description   = ""
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = "xml2go"
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake"
end
