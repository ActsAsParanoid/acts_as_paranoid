# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'acts_as_paranoid/version'

Gem::Specification.new do |spec|
  spec.name        = "acts_as_paranoid"
  spec.version     = ActsAsParanoid::VERSION
  spec.authors     = ["Zachary Scott", "Goncalo Silva", "Rick Olson"]
  spec.email       = ["e@zzak.io"]
  spec.summary     = "Active Record plugin which allows you to hide and restore records without actually deleting them."
  spec.description = "Check the home page for more in-depth information."
  spec.homepage    = "https://github.com/ActsAsParanoid/acts_as_paranoid"
  spec.license     = "MIT"

  spec.files         = Dir["{lib}/**/*.rb", "LICENSE", "*.md"]
  spec.test_files    = Dir["test/*.rb"]
  spec.require_paths = ["lib"]

  spec.required_rubygems_version = ">= 1.3.6"

  spec.add_dependency "activerecord", ">= 4.0", "< 5.1"
  spec.add_dependency "activesupport", ">= 4.0", "< 5.1"

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rdoc"
  spec.add_development_dependency "minitest", ">= 4.0", "<= 6.0"
end
