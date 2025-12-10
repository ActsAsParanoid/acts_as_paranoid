# frozen_string_literal: true

require "test_helper"

class ParanoidParent < ActiveRecord::Base
  acts_as_paranoid(handle_delete_all_associations: true)

  has_many :paranoid_children, dependent: :delete_all
end

class UnhandledDeleteParanoidParent < ActiveRecord::Base
  acts_as_paranoid

  has_many :paranoid_children, dependent: :delete_all
end


class ParanoidChild < ActiveRecord::Base
  acts_as_paranoid(handle_delete_all_associations: true)

  belongs_to :paranoid_parent
  has_many :paranoid_grandchildren, dependent: :delete_all
end

class ParanoidGrandchild < ActiveRecord::Base
  acts_as_paranoid(handle_delete_all_associations: true)

  belongs_to :paranoid_child
end

class ActsAsParanoidTest < ActiveSupport::TestCase
  def setup_db
    ActiveRecord::Schema.define(version: 1) do
      create_table :paranoid_parents do |t|
        t.datetime :deleted_at
        t.timestamps
      end

      create_table :unhandled_delete_paranoid_parents do |t|
        t.datetime :deleted_at
        t.timestamps
      end

      create_table :paranoid_children do |t|
        t.references :paranoid_parent, foreign_key: { on_delete: :cascade }
        t.references :unhandled_delete_paranoid_parent, foreign_key: { on_delete: :cascade }
        t.datetime :deleted_at
        t.timestamps
      end

      create_table :paranoid_grandchildren do |t|
        t.references :paranoid_child, foreign_key: { on_delete: :cascade }
        t.datetime :deleted_at
        t.timestamps
      end
    end
  end

  def setup
    setup_db
  end

  def teardown
    teardown_db
  end

  def test_deletes_all_children_when_deleting_parent
    parent = create_parent_with_children_and_grandchildren(child_count: 5)

    assert_difference("ParanoidChild.count", -5) { parent.destroy }
  end

  def test_soft_deletes_all_children_when_deleting_parent
    parent = create_parent_with_children_and_grandchildren(child_count: 5)

    assert_no_difference("ParanoidChild.with_deleted.count") { parent.destroy }
  end

  def test_deletes_all_grandchildren_when_deleting_parent
    parent = create_parent_with_children_and_grandchildren(child_count: 5)

    assert_difference("ParanoidGrandchild.count", -25) { parent.destroy }
  end

  def test_soft_deletes_all_grandchildren_when_deleting_parent
    parent = create_parent_with_children_and_grandchildren(child_count: 5)

    assert_no_difference("ParanoidGrandchild.with_deleted.count") { parent.destroy }
  end

  def test_makes_one_query_for_each_object_type_when_deleting_parent
    parent = create_parent_with_children_and_grandchildren(child_count: 5)

    query_count = count_queries do
      parent.destroy
    end

    # 1 query for parent, 1 for children, 1 for grandchildren, and 2 for the SQL TRANSACTION
    assert_equal(5, query_count)
  end

  def test_unsets_deleted_at_on_all_children_when_recovering_parent
    parent = create_parent_with_children_and_grandchildren(child_count: 5,
                                                           deleted_at: Time.current)

    assert_difference("ParanoidChild.count", 5) { parent.recover }
  end

  def test_unsets_deleted_at_on_all_grandchildren_when_restoring_parent
    parent = create_parent_with_children_and_grandchildren(child_count: 5,
                                                           deleted_at: Time.current)

    assert_difference("ParanoidGrandchild.count", 25) { parent.recover }
  end

  def test_makes_one_query_for_each_object_type_when_recovering_parent
    parent = create_parent_with_children_and_grandchildren(child_count: 5,
                                                           deleted_at: Time.current)

    query_count = count_queries do
      parent.recover
    end

    # 1 query for parent, 1 for children, 1 for grandchildren, 2 for the SQL TRANSACTION
    assert_equal(5, query_count)
  end

  def test_does_not_delete_all_grandchildren_when_handle_is_false
    parent = UnhandledDeleteParanoidParent.create

    child = parent.paranoid_children.create
    child.paranoid_grandchildren.create

    assert_difference("ParanoidGrandchild.count", 0) { parent.destroy }
  end

  private

  def count_queries(&block)
    count = 0

    counter_f = lambda { |_name, _started, _finished, _unique_id, payload|
      count += 1 unless payload[:name].in? %w[CACHE SCHEMA]
    }

    ActiveSupport::Notifications.subscribed(counter_f, "sql.active_record", &block)

    count
  end

  def create_parent_with_children_and_grandchildren(child_count:, deleted_at: nil)
    parent = ParanoidParent.create

    child_count.times do
      child = parent.paranoid_children.create
      child_count.times do
        child.paranoid_grandchildren.create
      end
    end

    if deleted_at
      ParanoidParent.update_all(deleted_at: deleted_at)
      ParanoidChild.update_all(deleted_at: deleted_at)
      ParanoidGrandchild.update_all(deleted_at: deleted_at)
    end

    parent.reload
  end
end
