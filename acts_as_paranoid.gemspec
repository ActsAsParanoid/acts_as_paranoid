# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "acts_as_paranoid/version"

Gem::Specification.new do |spec|
  spec.name        = "acts_as_paranoid"
  spec.version     = ActsAsParanoid::VERSION
  spec.authors     = ["Zachary Scott", "Goncalo Silva", "Rick Olson"]
  spec.email       = ["e@zzak.io"]
  spec.summary     = "Active Record plugin which allows you to hide and restore" \
    " records without actually deleting them."
  spec.description = "Check the home page for more in-depth information."
  spec.homepage    = "https://github.com/ActsAsParanoid/acts_as_paranoid"
  spec.license     = "MIT"

  spec.required_ruby_version = ">= 2.4.0"

  spec.files         = Dir["{lib}/**/*.rb", "LICENSE", "*.md"]
  spec.test_files    = Dir["test/*.rb"]
  spec.require_paths = ["lib"]

  spec.add_dependency "activerecord", ">= 5.2", "< 7.0"
  spec.add_dependency "activesupport", ">= 5.2", "< 7.0"

  spec.add_development_dependency "bundler", ">= 1.5", "< 3.0"
  spec.add_development_dependency "minitest", "~> 5.14"
  spec.add_development_dependency "minitest-focus", "~> 1.3.0"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rdoc"
  spec.add_development_dependency "rubocop", "~> 1.12.0"
  spec.add_development_dependency "simplecov", [">= 0.18.1", "< 0.22.0"]
end
