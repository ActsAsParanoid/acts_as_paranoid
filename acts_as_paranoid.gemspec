# frozen_string_literal: true

require_relative "lib/acts_as_paranoid/version"

Gem::Specification.new do |spec|
  spec.name = "acts_as_paranoid"
  spec.version = ActsAsParanoid::VERSION
  spec.authors = ["Zachary Scott", "Goncalo Silva", "Rick Olson"]
  spec.email = ["e@zzak.io"]

  spec.summary = "Active Record plugin which allows you to hide and restore" \
                 " records without actually deleting them."
  spec.description = "Check the home page for more in-depth information."
  spec.homepage = "https://github.com/ActsAsParanoid/acts_as_paranoid"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["changelog_uri"] = "https://github.com/ActsAsParanoid/acts_as_paranoid/blob/master/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = File.read("Manifest.txt").split
  spec.require_paths = ["lib"]

  spec.add_dependency "activerecord", ">= 6.1", "< 9"
  spec.add_dependency "activesupport", ">= 6.1", "< 8"

  spec.add_development_dependency "appraisal", "~> 2.3"
  spec.add_development_dependency "minitest", "~> 5.14"
  spec.add_development_dependency "minitest-around", "~> 0.5"
  spec.add_development_dependency "minitest-focus", "~> 1.3"
  spec.add_development_dependency "minitest-stub-const", "~> 0.6"
  spec.add_development_dependency "pry", "~> 0.14.1"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rake-manifest", "~> 0.2.0"
  spec.add_development_dependency "rdoc", "~> 6.3"
  spec.add_development_dependency "rubocop", "~> 1.52"
  spec.add_development_dependency "rubocop-minitest", "~> 0.36.0"
  spec.add_development_dependency "rubocop-packaging", "~> 0.5.2"
  spec.add_development_dependency "rubocop-performance", "~> 1.18"
  spec.add_development_dependency "rubocop-rake", "~> 0.6.0"
  spec.add_development_dependency "simplecov", "~> 0.22.0"
end
