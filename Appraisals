# frozen_string_literal: true

appraise "active_record_52" do
  gem "activerecord", "~> 5.2.0", require: "active_record"
  gem "activesupport", "~> 5.2.0", require: "active_support"
end

appraise "active_record_60" do
  gem "activerecord", "~> 6.0.0", require: "active_record"
  gem "activesupport", "~> 6.0.0", require: "active_support"

  group :development do
    gem "activerecord-jdbcsqlite3-adapter", "~> 60.0", platforms: [:jruby]
  end
end

appraise "active_record_61" do
  gem "activerecord", "~> 6.1.0", require: "active_record"
  gem "activesupport", "~> 6.1.0", require: "active_support"

  group :development do
    gem "activerecord-jdbcsqlite3-adapter", "~> 61.1", platforms: [:jruby]
  end
end

appraise "active_record_70" do
  gem "activerecord", "~> 7.0.0", require: "active_record"
  gem "activesupport", "~> 7.0.0", require: "active_support"

  group :development do
    gem "activerecord-jdbcsqlite3-adapter", "~> 70.0", platforms: [:jruby]
  end
end

appraise "active_record_71" do
  gem "activerecord", "~> 7.1.0.rc1", require: "active_record"
  gem "activesupport", "~> 7.1.0.rc1", require: "active_support"

  group :development do
    gem "activerecord-jdbcsqlite3-adapter", "~> 70.0", platforms: [:jruby]
  end
end
