# frozen_string_literal: true

require "simplecov"
SimpleCov.start do
  enable_coverage :branch
end

require "acts_as_paranoid"

require "minitest/autorun"
require "minitest/focus"
require "minitest/mock"
require "minitest/spec"
require "minitest/stub_const"
require "minitest/around"

# Silence deprecation halfway through the test
I18n.enforce_available_locales = true

ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
ActiveRecord::Schema.verbose = false

log_dir = File.expand_path("../log/", __dir__)
FileUtils.mkdir_p log_dir
file_path = File.join(log_dir, "test.log")
ActiveRecord::Base.logger = Logger.new(file_path)

def timestamps(table)
  table.column :created_at, :timestamp, null: false
  table.column :updated_at, :timestamp, null: false
end

module ParanoidTestHelpers
  def assert_paranoid_deletion(model)
    row = find_row(model)

    assert_not_nil row, "#{model.class} entirely deleted"
    assert_not_nil row["deleted_at"], "Deleted at not set"
  end

  def assert_non_paranoid_deletion(model)
    row = find_row(model)

    assert_nil row, "#{model.class} still exists"
  end

  def find_row(model)
    sql = "select deleted_at from #{model.class.table_name} where id = #{model.id}"
    # puts sql here if you want to debug
    model.class.connection.select_one(sql)
  end

  def teardown_db
    ActiveRecord::Base.connection.data_sources.each do |table|
      ActiveRecord::Base.connection.drop_table(table)
    end
  end
end

ActiveSupport::TestCase.include ParanoidTestHelpers
