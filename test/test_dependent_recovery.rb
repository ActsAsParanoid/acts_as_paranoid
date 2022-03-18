# frozen_string_literal: true

require "test_helper"

class DependentRecoveryTest < ActiveSupport::TestCase
  class ParanoidForest < ActiveRecord::Base
    acts_as_paranoid
    has_many :paranoid_trees, dependent: :destroy
  end

  class ParanoidTree < ActiveRecord::Base
    acts_as_paranoid
    belongs_to :paranoid_forest, optional: false
  end

  def setup
    ActiveRecord::Schema.define(version: 1) do
      create_table :paranoid_forests do |t|
        t.string   :name
        t.boolean  :rainforest
        t.datetime :deleted_at

        timestamps t
      end

      create_table :paranoid_trees do |t|
        t.integer  :paranoid_forest_id
        t.string   :name
        t.datetime :deleted_at

        timestamps t
      end
    end
  end

  def teardown
    teardown_db
  end

  def test_recover_dependent_records_with_required_belongs_to
    forest = ParanoidForest.create! name: "forest"

    tree = ParanoidTree.new name: "tree"
    refute tree.valid?
    tree.paranoid_forest = forest
    assert_predicate tree, :valid?
    tree.save!

    forest.destroy
    forest.recover

    assert_equal 1, ParanoidTree.count
  end
end
