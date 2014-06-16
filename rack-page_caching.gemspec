# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rack/page_caching/version'

Gem::Specification.new do |spec|
  spec.name          = "rack-page_caching"
  spec.version       = Rack::PageCaching::VERSION
  spec.authors       = ["Wayne See"]
  spec.email         = ["weynsee@gmail.com"]
  spec.summary       = %q{Page caching for Rack.}
  spec.description   = %q{Rack middleware to generate pages that can be served by a web server. Compatible with Rails page caching.}
  spec.homepage      = "https://github.com/weynsee/rack-page_caching"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.required_ruby_version = '>= 1.9.3'

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "minitest"
  spec.add_development_dependency "rack-test"
  spec.add_development_dependency "appraisal"
  spec.add_development_dependency "rails", ">= 3"
  spec.add_dependency "rack"
end
