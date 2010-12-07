# coding: UTF-8

Gem::Specification.new do |s|
  s.name              = "gravelpup-rails3_acts_as_paranoid"
  s.version           = "0.0.3"
  s.platform          = Gem::Platform::RUBY
  s.authors           = ["Gonçalo Silva", "Jonathan Vaught"]
  s.email             = ["jonathan.vaught@gmail.com"]
  s.homepage          = "http://github.com/gravelpup/rails3_acts_as_paranoid"
  s.summary           = "Active Record (>=3.0) plugin which allows you to hide and restore records without actually deleting them."
  s.description       = "Active Record (>=3.0) plugin which allows you to hide and restore records without actually deleting them. Check its GitHub page for more in-depth information."
  s.rubyforge_project = s.name

  s.required_rubygems_version = ">= 1.3.7"
  
  s.add_dependency "activerecord", ">= 3.0"

  s.files        = Dir["{lib}/**/*.rb", "LICENSE", "*.markdown"]
  s.require_path = 'lib'
end
