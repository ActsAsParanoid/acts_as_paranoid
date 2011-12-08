require 'test_helper'

class MoreParanoidTest < ParanoidBaseTest
  test "cannot find a paranoid deleted many:many association" do
    left = ParanoidManyManyParentLeft.create
    right = ParanoidManyManyParentRight.create
    left.paranoid_many_many_parent_rights << right
    
    child = left.paranoid_many_many_children.first

    left.paranoid_many_many_parent_rights.delete(right)

    left.reload
    
    assert_equal [], left.paranoid_many_many_children
    assert_equal [], left.paranoid_many_many_parent_rights, "Associated objects not deleted"
    assert_equal right, ParanoidManyManyParentRight.find(right.id)
  end
  
  test "cannot find a paranoid destroyed many:many association" do
    left = ParanoidManyManyParentLeft.create
    right = ParanoidManyManyParentRight.create
    left.paranoid_many_many_parent_rights << right
    
    child = left.paranoid_many_many_children.first

    left.paranoid_many_many_parent_rights.destroy(right)
    
    left.reload
    
    assert_equal [], left.paranoid_many_many_children, "Child records still exist"
    assert_equal [], left.paranoid_many_many_parent_rights, "Associated objects not deleted"
    assert_equal right, ParanoidManyManyParentRight.find(right.id)
  end
  
  test "cannot find a has_many :through object when its linking object is paranoid destroyed" do
    left = ParanoidManyManyParentLeft.create
    right = ParanoidManyManyParentRight.create
    left.paranoid_many_many_parent_rights << right
    
    child = left.paranoid_many_many_children.first

    child.destroy
    
    left.reload
    
    assert_equal [], left.paranoid_many_many_parent_rights, "Associated objects not deleted"
  end
  
  test "cannot find a paranoid deleted model" do
    model = ParanoidBelongsDependant.create
    model.destroy
    
    assert_raises ActiveRecord::RecordNotFound do
      ParanoidBelongsDependant.find(model.id)
    end
  end
  
  test "bidirectional has_many :through association clear is paranoid" do
    left = ParanoidManyManyParentLeft.create
    right = ParanoidManyManyParentRight.create
    left.paranoid_many_many_parent_rights << right
    
    child = left.paranoid_many_many_children.first
    assert_equal left, child.paranoid_many_many_parent_left, "Child's left parent is incorrect"
    assert_equal right, child.paranoid_many_many_parent_right, "Child's right parent is incorrect"
    
    left.paranoid_many_many_parent_rights.clear
    
    assert_paranoid_deletion(child)
  end
  
  test "bidirectional has_many :through association destroy is paranoid" do
    left = ParanoidManyManyParentLeft.create
    right = ParanoidManyManyParentRight.create
    left.paranoid_many_many_parent_rights << right
    
    child = left.paranoid_many_many_children.first
    assert_equal left, child.paranoid_many_many_parent_left, "Child's left parent is incorrect"
    assert_equal right, child.paranoid_many_many_parent_right, "Child's right parent is incorrect"
    
    left.paranoid_many_many_parent_rights.destroy(right)
    
    assert_paranoid_deletion(child)
  end
  
  test "bidirectional has_many :through association delete is paranoid" do
    left = ParanoidManyManyParentLeft.create
    right = ParanoidManyManyParentRight.create
    left.paranoid_many_many_parent_rights << right
    
    child = left.paranoid_many_many_children.first
    assert_equal left, child.paranoid_many_many_parent_left, "Child's left parent is incorrect"
    assert_equal right, child.paranoid_many_many_parent_right, "Child's right parent is incorrect"
    
    left.paranoid_many_many_parent_rights.delete(right)
    
    assert_paranoid_deletion(child)
  end
  
  test "delete by multiple id is paranoid" do
    model_a = ParanoidBelongsDependant.create
    model_b = ParanoidBelongsDependant.create
    ParanoidBelongsDependant.delete([model_a.id, model_b.id])
    
    assert_paranoid_deletion(model_a)
    assert_paranoid_deletion(model_b)
  end
  
  test "destroy by multiple id is paranoid" do
    model_a = ParanoidBelongsDependant.create
    model_b = ParanoidBelongsDependant.create
    ParanoidBelongsDependant.destroy([model_a.id, model_b.id])
    
    assert_paranoid_deletion(model_a)
    assert_paranoid_deletion(model_b)
  end
  
  test "delete by single id is paranoid" do
    model = ParanoidBelongsDependant.create
    ParanoidBelongsDependant.delete(model.id)
    
    assert_paranoid_deletion(model)
  end
  
  test "destroy by single id is paranoid" do
    model = ParanoidBelongsDependant.create
    ParanoidBelongsDependant.destroy(model.id)
    
    assert_paranoid_deletion(model)
  end
  
  test "instance delete is paranoid" do
    model = ParanoidBelongsDependant.create
    model.delete
    
    assert_paranoid_deletion(model)
  end
  
  test "instance destroy is paranoid" do
    model = ParanoidBelongsDependant.create
    model.destroy
    
    assert_paranoid_deletion(model)
  end

  def find_row(model)
    sql = "select deleted_at from #{model.class.table_name} where id = #{model.id}"
    # puts sql here if you want to debug
    model.class.connection.select_one(sql)
  end
  
  def assert_paranoid_deletion(model)
    row = find_row(model)
    assert_not_nil row, "#{model.class} entirely deleted"
    assert_not_nil row["deleted_at"], "Deleted at not set"
  end
  
  def assert_non_paranoid_deletion(model)
    row = find_row(model)
    assert_nil row, "#{model.class} still exists"
  end
end