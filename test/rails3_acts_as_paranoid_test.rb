require 'test_helper'

#["paranoid", "really paranoid", "extremely paranoid"].each do |name|
#  Parent.create! :name => name
#  Son.create! :name => name
#end
#Parent.first.destroy
#Son.delete_all("name = 'paranoid' OR name = 'really paranoid'")
#Parent.count
#Son.count
#Parent.only_deleted.count 
#Son.only_deleted.count
#Parent.with_deleted.count
#Son.with_deleted.count

class ParanoidBase < ActiveSupport::TestCase
  def setup
    setup_db
    
    ["paranoid", "really paranoid", "extremely paranoid"].each do |name|
      ParanoidTime.create! :name => name
      ParanoidBoolean.create! :name => name
    end

    NotParanoid.create! :name => "no paranoid goals"
  end

  def teardown
    teardown_db
  end

  def assert_exception(exception)
    begin
      begin
        yield
      rescue exception
        true
      end
    rescue
      false
    end
  end
end

class ParanoidTest < ParanoidBase
  def test_fake_removal
    assert_equal 3, ParanoidTime.count
    assert_equal 3, ParanoidBoolean.count

    ParanoidTime.first.destroy
    ParanoidBoolean.delete_all("name = 'paranoid' OR name = 'really paranoid'")
    assert_equal 2, ParanoidTime.count
    assert_equal 1, ParanoidBoolean.count
    assert_equal 1, ParanoidTime.only_deleted.count 
    assert_equal 2, ParanoidBoolean.only_deleted.count
    assert_equal 3, ParanoidTime.with_deleted.count
    assert_equal 3, ParanoidBoolean.with_deleted.count
  end

  def test_real_removal
    ParanoidTime.first.destroy!
    ParanoidBoolean.delete_all!("name = 'extremely paranoid' OR name = 'really paranoid'")
    assert_equal 2, ParanoidTime.count
    assert_equal 1, ParanoidBoolean.count
    assert_equal 2, ParanoidTime.with_deleted.count
    assert_equal 1, ParanoidBoolean.with_deleted.count
    assert_equal 0, ParanoidBoolean.only_deleted.count
    assert_equal 0, ParanoidTime.only_deleted.count

    ParanoidTime.first.destroy
    ParanoidTime.only_deleted.first.destroy
    assert_equal 0, ParanoidTime.only_deleted.count

    ParanoidTime.delete_all!
    assert_empty ParanoidTime.all
    assert_empty ParanoidTime.with_deleted.all    
  end

  def test_paranoid_scope
    assert_exception(NoMethodError) { NotParanoid.delete_all! }
    assert_exception(NoMethodError) { NotParanoid.first.destroy! }
    assert_exception(NoMethodError) { NotParanoid.with_deleted }
    assert_exception(NoMethodError) { NotParanoid.only_deleted }    
  end

  def test_recovery
    assert_equal 3, ParanoidBoolean.count
    ParanoidBoolean.first.destroy
    assert_equal 2, ParanoidBoolean.count
    ParanoidBoolean.only_deleted.first.recover
    assert_equal 3, ParanoidBoolean.count
  end
end

class ValidatesUniquenessTest < ParanoidBase
  def test_should_include_deleted_by_default
    ParanoidTime.new(:name => 'paranoid').tap do |record|
      assert !record.valid?
      ParanoidTime.first.destroy
      assert !record.valid?
      ParanoidTime.only_deleted.first.destroy!
      assert record.valid?
    end
  end

  def test_should_validate_without_deleted
    ParanoidBoolean.first.destroy
    assert ParanoidBoolean.new(:name => 'paranoid').valid?
    ParanoidBoolean.only_deleted.first.destroy!
    assert ParanoidBoolean.new(:name => 'paranoid').valid?
  end
end