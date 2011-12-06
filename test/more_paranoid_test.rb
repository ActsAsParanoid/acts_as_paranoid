require 'test_helper'

class MoreParanoidTest < ParanoidBaseTest
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