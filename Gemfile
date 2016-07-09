source "https://rubygems.org"

# Development dependencies
group :development do
  gem "activerecord", "~> 3.2", :require => "active_record"
  gem "activesupport", "~> 3.2", :require => "active_support"

  gem "sqlite3", :platforms => [:ruby]
  gem "activerecord-jdbcsqlite3-adapter", :platforms => [:jruby]

  if RUBY_VERSION < "1.9"
    gem "i18n", "~> 0.6.11"
    gem "rake", "10.0.0"
  end
end

group :test do
  gem 'test-unit', '~> 3.0'
end

gemspec
