source "http://rubygems.org"

gem "activerecord", "~>3.2"

# Development dependencies
gem "rake"
gem "activesupport", "~>3.2"

platforms :ruby do
  gem "sqlite3"
end

platforms :jruby do
  gem "activerecord-jdbcsqlite3-adapter"
end

group :test do
  gem "minitest"
  gem "autotest-growl"
end
