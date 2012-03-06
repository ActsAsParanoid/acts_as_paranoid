Gem::Specification.new do |s|
  s.name              = "rails3_acts_as_paranoid"
  s.version           = "0.1.4"
  s.platform          = Gem::Platform::RUBY
  s.authors           = ["Goncalo Silva"]
  s.email             = ["goncalossilva@gmail.com"]
  s.homepage          = "https://github.com/softcraft-development/rails3_acts_as_paranoid"
  s.summary           = "Active Record (~>3.1) plugin which allows you to hide and restore records without actually deleting them."
  s.description       = "Active Record (~>3.1) plugin which allows you to hide and restore records without actually deleting them. Check its GitHub page for more in-depth information."
  s.rubyforge_project = s.name

  s.required_rubygems_version = ">= 1.3.6"
  
  s.add_dependency "activerecord", "~> 3.1"

  s.files        = Dir["{lib}/**/*.rb", "LICENSE", "*.markdown"]
end
