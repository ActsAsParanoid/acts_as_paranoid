require 'test_helper'

class ParanoidBase < ActiveSupport::TestCase
  def assert_empty(collection)
    assert(collection.respond_to?(:empty?) && collection.empty?)
  end
  
  def setup
    setup_db

    ["paranoid", "really paranoid", "extremely paranoid"].each do |name|
      ParanoidTime.create! :name => name
      ParanoidBoolean.create! :name => name
    end

    NotParanoid.create! :name => "no paranoid goals"
    ParanoidWithCallback.create! :name => 'paranoid with callbacks'
  end

  def teardown
    teardown_db
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
    assert_raise(NoMethodError) { NotParanoid.delete_all! }
    assert_raise(NoMethodError) { NotParanoid.first.destroy! }
    assert_raise(NoMethodError) { NotParanoid.with_deleted }
    assert_raise(NoMethodError) { NotParanoid.only_deleted }    
  end

  def test_recovery
    assert_equal 3, ParanoidBoolean.count
    ParanoidBoolean.first.destroy
    assert_equal 2, ParanoidBoolean.count
    ParanoidBoolean.only_deleted.first.recover
    assert_equal 3, ParanoidBoolean.count
  end

  def setup_recursive_recovery_tests
    @paranoid_time_object = ParanoidTime.first

    @paranoid_boolean_count = ParanoidBoolean.count

    assert_equal 0, ParanoidHasManyDependant.count
    assert_equal 0, ParanoidBelongsDependant.count

    (1..3).each do |i|
      has_many_object = @paranoid_time_object.paranoid_has_many_dependants.create(:name => "has_many_#{i}")
      has_many_object.create_paranoid_belongs_dependant(:name => "belongs_to_#{i}")
      has_many_object.save

      paranoid_boolean = @paranoid_time_object.paranoid_booleans.create(:name => "boolean_#{i}")
      paranoid_boolean.create_paranoid_has_one_dependant(:name => "has_one_#{i}")
      paranoid_boolean.save

      @paranoid_time_object.not_paranoids.create(:name => "not_paranoid_a#{i}")

    end

    @paranoid_time_object.create_not_paranoid(:name => "not_paranoid_belongs_to")

    @paranoid_time_object.create_has_one_not_paranoid(:name => "has_one_not_paranoid")

    assert_equal 3, ParanoidTime.count
    assert_equal 3, ParanoidHasManyDependant.count
    assert_equal 3, ParanoidBelongsDependant.count
    assert_equal 3, ParanoidHasOneDependant.count
    assert_equal 5, NotParanoid.count
    assert_equal 1, HasOneNotParanoid.count
    assert_equal @paranoid_boolean_count + 3, ParanoidBoolean.count

    @paranoid_time_object.destroy
    @paranoid_time_object.reload

    assert_equal 2, ParanoidTime.count
    assert_equal 0, ParanoidHasManyDependant.count
    assert_equal 0, ParanoidBelongsDependant.count
    assert_equal 0, ParanoidHasOneDependant.count

    assert_equal 1, NotParanoid.count
    assert_equal 0, HasOneNotParanoid.count
    assert_equal @paranoid_boolean_count, ParanoidBoolean.count
  end

  def test_recursive_recovery
    setup_recursive_recovery_tests

    @paranoid_time_object.recover(:recursive => true)

    assert_equal 3, ParanoidTime.count
    assert_equal 3, ParanoidHasManyDependant.count
    assert_equal 3, ParanoidBelongsDependant.count
    assert_equal 3, ParanoidHasOneDependant.count
    assert_equal 1, NotParanoid.count
    assert_equal 0, HasOneNotParanoid.count
    assert_equal @paranoid_boolean_count + 3, ParanoidBoolean.count
  end

  def test_non_recursive_recovery
    setup_recursive_recovery_tests

    @paranoid_time_object.recover(:recursive => false)

    assert_equal 3, ParanoidTime.count
    assert_equal 0, ParanoidHasManyDependant.count
    assert_equal 0, ParanoidBelongsDependant.count
    assert_equal 0, ParanoidHasOneDependant.count
    assert_equal 1, NotParanoid.count
    assert_equal 0, HasOneNotParanoid.count
    assert_equal @paranoid_boolean_count, ParanoidBoolean.count
  end

  def test_deleted?
    ParanoidTime.first.destroy
    assert ParanoidTime.with_deleted.first.deleted?
  end
  
  def test_paranoid_destroy_callbacks    
    @paranoid_with_callback = ParanoidWithCallback.first
    ParanoidWithCallback.transaction do
      @paranoid_with_callback.destroy
    end
    
    assert @paranoid_with_callback.called_before_destroy
    assert @paranoid_with_callback.called_after_destroy
    assert @paranoid_with_callback.called_after_commit_on_destroy
  end
  
  def test_hard_destroy_callbacks
    @paranoid_with_callback = ParanoidWithCallback.first
    
    ParanoidWithCallback.transaction do
      @paranoid_with_callback.destroy!
    end
    
    assert @paranoid_with_callback.called_before_destroy
    assert @paranoid_with_callback.called_after_destroy
    assert @paranoid_with_callback.called_after_commit_on_destroy
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
    ParanoidBoolean.new(:name => 'paranoid').tap do |record|
      ParanoidBoolean.first.destroy
      assert record.valid?
      ParanoidBoolean.only_deleted.first.destroy!
      assert record.valid?
    end
  end
end
