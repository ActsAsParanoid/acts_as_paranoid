Gem::Specification.new do |s|
  s.name                  = "acts_as_paranoid"
  s.version               = "0.4.2"
  s.platform              = Gem::Platform::RUBY
  s.authors               = ["Goncalo Silva", "Charles G.", "Rick Olson"]
  s.email                 = ["goncalossilva@gmail.com"]
  s.homepage              = "https://github.com/goncalossilva/rails3_acts_as_paranoid"
  s.summary               = "Active Record (~>3.2) plugin which allows you to hide and restore records without actually deleting them."
  s.description           = "Active Record (~>3.2) plugin which allows you to hide and restore records without actually deleting them. Check its GitHub page for more in-depth information."
  s.rubyforge_project     = s.name

  s.required_rubygems_version = ">= 1.3.6"

  s.add_dependency "activerecord", "~> 3.2"

  s.files        = Dir["{lib}/**/*.rb", "LICENSE", "*.markdown"]
end
