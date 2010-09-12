# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

Gem::Specification.new do |s|
  s.name        = "rails3_acts_as_paranoid"
  s.version     = "0.0.1"
  s.platform    = Gem::Platform::RUBY
  s.authors     = "Gonçalo Silva"
  s.email       = "goncalossilva@gmail.com"
  s.homepage    = "http://github.com/goncalossilva/rails3_acts_as_paranoid"
  s.summary     = "ActiveRecord (>=3.0) plugin which allows you to hide and restore records without actually deleting them."
  s.description = "ActiveRecord (>=3.0) plugin which allows you to hide and restore records without actually deleting them."
  s.files        = Dir.glob("lib/**/*") + %w(MIT-LICENSE README.markdown Rakefile)
  s.require_path = 'lib'
end
