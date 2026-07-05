# frozen_string_literal: true

source "https://rubygems.org"

# Development dependencies
group :development do
  # Pin rbs to a version that installs on jruby.
  # See https://github.com/ruby/rdoc/issues/1746
  # TODO: Remove or adjust this once 4.1.0 is released
  gem "rbs", "4.1.0.pre2", platforms: [:jruby]
  gem "sqlite3", ">= 1.4", "< 3.0", platforms: [:ruby]
end

gemspec
