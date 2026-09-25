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
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "https://github.com/ActsAsParanoid/acts_as_paranoid/blob/master/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = File.read("Manifest.txt").split
  spec.require_paths = ["lib"]

  spec.add_dependency "activerecord", ">= 7.2", "< 8.2"
  spec.add_dependency "activesupport", ">= 7.2", "< 8.2"
end
