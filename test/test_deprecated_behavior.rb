# frozen_string_literal: true

require "test_helper"

class DeprecatedBehaviorTest < ActiveSupport::TestCase
  class StringlyParanoid < ActiveRecord::Base
    acts_as_paranoid column_type: "string", column: "foo", recovery_value: "alive"
  end

  def setup
    ActiveRecord::Schema.define(version: 1) do
      create_table :stringly_paranoids do |t|
        t.string :foo

        timestamps t
      end
    end
  end

  def teardown
    teardown_db
  end

  def test_recovery_value
    record = StringlyParanoid.create!
    record.destroy
    record.recover
    assert_equal "alive", record.paranoid_value
  end
end
