# frozen_string_literal: true

require "test_helper"

class TableNamespaceTest < ActiveSupport::TestCase
  module Paranoid
    class Blob < ActiveRecord::Base
      acts_as_paranoid

      validates_presence_of :name

      def self.table_name_prefix
        "paranoid_"
      end
    end
  end

  def setup
    ActiveRecord::Schema.define(version: 1) do
      create_table :paranoid_blobs do |t|
        t.string   :name
        t.datetime :deleted_at

        timestamps t
      end
    end
  end

  def teardown
    teardown_db
  end

  def test_correct_table_name
    assert_equal "paranoid_blobs", Paranoid::Blob.table_name

    b = Paranoid::Blob.new(name: "hello!")
    b.save!
    assert_equal b, Paranoid::Blob.first
  end
end
