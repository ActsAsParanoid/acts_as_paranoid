require 'test_helper'

class RelationsTest < ParanoidBaseTest
  def setup
    setup_db

    @paranoid_forest_1 = ParanoidForest.create! :name => "ParanoidForest #1"
    @paranoid_forest_2 = ParanoidForest.create! :name => "ParanoidForest #2", :rainforest => true
    @paranoid_forest_3 = ParanoidForest.create! :name => "ParanoidForest #3", :rainforest => true

    assert_equal 3, ParanoidForest.count
    assert_equal 2, ParanoidForest.rainforest.count

    @paranoid_forest_1.paranoid_trees.create! :name => 'ParanoidTree #1'
    @paranoid_forest_1.paranoid_trees.create! :name => 'ParanoidTree #2'
    @paranoid_forest_2.paranoid_trees.create! :name => 'ParanoidTree #3'
    @paranoid_forest_2.paranoid_trees.create! :name => 'ParanoidTree #4'

    assert_equal 4, ParanoidTree.count
  end

  def test_filtering_with_scopes
    assert_equal 2, ParanoidForest.rainforest.with_deleted.count
    assert_equal 2, ParanoidForest.with_deleted.rainforest.count

    assert_equal 0, ParanoidForest.rainforest.only_deleted.count
    assert_equal 0, ParanoidForest.only_deleted.rainforest.count

    ParanoidForest.rainforest.first.destroy
    assert_equal 1, ParanoidForest.rainforest.count

    assert_equal 2, ParanoidForest.rainforest.with_deleted.count
    assert_equal 2, ParanoidForest.with_deleted.rainforest.count

    assert_equal 1, ParanoidForest.rainforest.only_deleted.count
    assert_equal 1, ParanoidForest.only_deleted.rainforest.count
  end

  def test_associations_filtered_by_with_deleted
    assert_equal 2, @paranoid_forest_1.paranoid_trees.with_deleted.count
    assert_equal 2, @paranoid_forest_2.paranoid_trees.with_deleted.count

    @paranoid_forest_1.paranoid_trees.first.destroy
    assert_equal 1, @paranoid_forest_1.paranoid_trees.count
    assert_equal 2, @paranoid_forest_1.paranoid_trees.with_deleted.count
    assert_equal 4, ParanoidTree.with_deleted.count

    @paranoid_forest_2.paranoid_trees.first.destroy
    assert_equal 1, @paranoid_forest_2.paranoid_trees.count
    assert_equal 2, @paranoid_forest_2.paranoid_trees.with_deleted.count
    assert_equal 4, ParanoidTree.with_deleted.count

    @paranoid_forest_1.paranoid_trees.first.destroy
    assert_equal 0, @paranoid_forest_1.paranoid_trees.count
    assert_equal 2, @paranoid_forest_1.paranoid_trees.with_deleted.count
    assert_equal 4, ParanoidTree.with_deleted.count
  end

  def test_associations_filtered_by_only_deleted
    assert_equal 0, @paranoid_forest_1.paranoid_trees.only_deleted.count
    assert_equal 0, @paranoid_forest_2.paranoid_trees.only_deleted.count

    @paranoid_forest_1.paranoid_trees.first.destroy
    assert_equal 1, @paranoid_forest_1.paranoid_trees.only_deleted.count
    assert_equal 1, ParanoidTree.only_deleted.count

    @paranoid_forest_2.paranoid_trees.first.destroy
    assert_equal 1, @paranoid_forest_2.paranoid_trees.only_deleted.count
    assert_equal 2, ParanoidTree.only_deleted.count

    @paranoid_forest_1.paranoid_trees.first.destroy
    assert_equal 2, @paranoid_forest_1.paranoid_trees.only_deleted.count
    assert_equal 3, ParanoidTree.only_deleted.count
  end

  def test_fake_removal_through_relation
    # destroy: through a relation.
    ParanoidForest.rainforest.destroy(@paranoid_forest_3.id)
    assert_equal 1, ParanoidForest.rainforest.count
    assert_equal 2, ParanoidForest.rainforest.with_deleted.count
    assert_equal 1, ParanoidForest.rainforest.only_deleted.count

    # destroy_all: through a relation
    @paranoid_forest_2.paranoid_trees.order(:id).destroy_all
    assert_equal 0, @paranoid_forest_2.paranoid_trees(true).count
    assert_equal 2, @paranoid_forest_2.paranoid_trees(true).with_deleted.count
  end

  def test_real_removal_through_relation
    # destroy!: aliased to delete
    ParanoidForest.rainforest.destroy!(@paranoid_forest_3)
    assert_equal 1, ParanoidForest.rainforest.count
    assert_equal 1, ParanoidForest.rainforest.with_deleted.count
    assert_equal 0, ParanoidForest.rainforest.only_deleted.count

    # destroy: two-step through a relation
    paranoid_tree = @paranoid_forest_1.paranoid_trees.first
    @paranoid_forest_1.paranoid_trees.order(:id).destroy(paranoid_tree.id)
    @paranoid_forest_1.paranoid_trees.only_deleted.destroy(paranoid_tree.id)
    assert_equal 1, @paranoid_forest_1.paranoid_trees(true).count
    assert_equal 1, @paranoid_forest_1.paranoid_trees(true).with_deleted.count
    assert_equal 0, @paranoid_forest_1.paranoid_trees(true).only_deleted.count

    # destroy_all: two-step through a relation
    @paranoid_forest_1.paranoid_trees.order(:id).destroy_all
    @paranoid_forest_1.paranoid_trees.only_deleted.destroy_all
    assert_equal 0, @paranoid_forest_1.paranoid_trees(true).count
    assert_equal 0, @paranoid_forest_1.paranoid_trees(true).with_deleted.count
    assert_equal 0, @paranoid_forest_1.paranoid_trees(true).only_deleted.count

    # delete_all!: through a relation
    @paranoid_forest_2.paranoid_trees.order(:id).delete_all!
    assert_equal 0, @paranoid_forest_2.paranoid_trees(true).count
    assert_equal 0, @paranoid_forest_2.paranoid_trees(true).with_deleted.count
    assert_equal 0, @paranoid_forest_2.paranoid_trees(true).only_deleted.count
  end
end
