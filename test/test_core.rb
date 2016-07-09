require 'test_helper'

class ParanoidTest < ParanoidBaseTest
  def test_paranoid?
    assert !NotParanoid.paranoid?
    assert_raise(NoMethodError) { NotParanoid.delete_all! }
    assert_raise(NoMethodError) { NotParanoid.with_deleted }
    assert_raise(NoMethodError) { NotParanoid.only_deleted }

    assert ParanoidTime.paranoid?
  end

  def test_scope_inclusion_with_time_column_type
    assert ParanoidTime.respond_to?(:deleted_inside_time_window)
    assert ParanoidTime.respond_to?(:deleted_before_time)
    assert ParanoidTime.respond_to?(:deleted_after_time)

    assert !ParanoidBoolean.respond_to?(:deleted_inside_time_window)
    assert !ParanoidBoolean.respond_to?(:deleted_before_time)
    assert !ParanoidBoolean.respond_to?(:deleted_after_time)
  end

  def test_fake_removal
    assert_equal 3, ParanoidTime.count
    assert_equal 3, ParanoidBoolean.count
    assert_equal 1, ParanoidString.count

    ParanoidTime.first.destroy
    ParanoidBoolean.delete_all("name = 'paranoid' OR name = 'really paranoid'")
    ParanoidString.first.destroy
    assert_equal 2, ParanoidTime.count
    assert_equal 1, ParanoidBoolean.count
    assert_equal 0, ParanoidString.count
    assert_equal 1, ParanoidTime.only_deleted.count
    assert_equal 2, ParanoidBoolean.only_deleted.count
    assert_equal 1, ParanoidString.only_deleted.count
    assert_equal 3, ParanoidTime.with_deleted.count
    assert_equal 3, ParanoidBoolean.with_deleted.count
    assert_equal 1, ParanoidString.with_deleted.count
  end

  def test_real_removal
    ParanoidTime.first.destroy_fully!
    ParanoidBoolean.delete_all!("name = 'extremely paranoid' OR name = 'really paranoid'")
    ParanoidString.first.destroy_fully!
    assert_equal 2, ParanoidTime.count
    assert_equal 1, ParanoidBoolean.count
    assert_equal 0, ParanoidString.count
    assert_equal 2, ParanoidTime.with_deleted.count
    assert_equal 1, ParanoidBoolean.with_deleted.count
    assert_equal 0, ParanoidString.with_deleted.count
    assert_equal 0, ParanoidTime.only_deleted.count
    assert_equal 0, ParanoidBoolean.only_deleted.count
    assert_equal 0, ParanoidString.only_deleted.count

    ParanoidTime.first.destroy
    ParanoidTime.only_deleted.first.destroy
    assert_equal 0, ParanoidTime.only_deleted.count

    ParanoidTime.delete_all!
    assert_empty ParanoidTime.all
    assert_empty ParanoidTime.with_deleted
  end

  def test_non_persisted_destroy
    pt = ParanoidTime.new
    assert_nil pt.paranoid_value
    pt.destroy
    assert_not_nil pt.paranoid_value
  end

  def test_non_persisted_destroy!
    pt = ParanoidTime.new
    assert_nil pt.paranoid_value
    pt.destroy!
    assert_not_nil pt.paranoid_value
  end

  def test_removal_not_persisted
    assert ParanoidTime.new.destroy
  end

  def test_recovery
    assert_equal 3, ParanoidBoolean.count
    ParanoidBoolean.first.destroy
    assert_equal 2, ParanoidBoolean.count
    ParanoidBoolean.only_deleted.first.recover
    assert_equal 3, ParanoidBoolean.count

    assert_equal 1, ParanoidString.count
    ParanoidString.first.destroy
    assert_equal 0, ParanoidString.count
    ParanoidString.with_deleted.first.recover
    assert_equal 1, ParanoidString.count
  end

  def setup_recursive_tests
    @paranoid_time_object = ParanoidTime.first

    # Create one extra ParanoidHasManyDependant record so that we can validate
    # the correct dependants are recovered.
    ParanoidTime.where('id <> ?', @paranoid_time_object.id).first.paranoid_has_many_dependants.create(:name => "should not be recovered").destroy

    @paranoid_boolean_count = ParanoidBoolean.count

    assert_equal 0, ParanoidHasManyDependant.count
    assert_equal 0, ParanoidBelongsDependant.count
    assert_equal 1, NotParanoid.count

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
    assert_equal @paranoid_boolean_count + 3, ParanoidBoolean.count
    assert_equal 3, ParanoidHasOneDependant.count
    assert_equal 5, NotParanoid.count
    assert_equal 1, HasOneNotParanoid.count
  end

  def test_recursive_fake_removal
    setup_recursive_tests

    @paranoid_time_object.destroy

    assert_equal 2, ParanoidTime.count
    assert_equal 0, ParanoidHasManyDependant.count
    assert_equal 0, ParanoidBelongsDependant.count
    assert_equal @paranoid_boolean_count, ParanoidBoolean.count
    assert_equal 0, ParanoidHasOneDependant.count
    assert_equal 1, NotParanoid.count
    assert_equal 0, HasOneNotParanoid.count

    assert_equal 3, ParanoidTime.with_deleted.count
    assert_equal 4, ParanoidHasManyDependant.with_deleted.count
    assert_equal 3, ParanoidBelongsDependant.with_deleted.count
    assert_equal @paranoid_boolean_count + 3, ParanoidBoolean.with_deleted.count
    assert_equal 3, ParanoidHasOneDependant.with_deleted.count
  end

  def test_recursive_real_removal
    setup_recursive_tests

    @paranoid_time_object.destroy_fully!

    assert_equal 0, ParanoidTime.only_deleted.count
    assert_equal 1, ParanoidHasManyDependant.only_deleted.count
    assert_equal 0, ParanoidBelongsDependant.only_deleted.count
    assert_equal 0, ParanoidBoolean.only_deleted.count
    assert_equal 0, ParanoidHasOneDependant.only_deleted.count
    assert_equal 1, NotParanoid.count
    assert_equal 0, HasOneNotParanoid.count
  end

  def test_recursive_recovery
    setup_recursive_tests

    @paranoid_time_object.destroy
    @paranoid_time_object.reload

    @paranoid_time_object.recover(:recursive => true)

    assert_equal 3, ParanoidTime.count
    assert_equal 3, ParanoidHasManyDependant.count
    assert_equal 3, ParanoidBelongsDependant.count
    assert_equal @paranoid_boolean_count + 3, ParanoidBoolean.count
    assert_equal 3, ParanoidHasOneDependant.count
    assert_equal 1, NotParanoid.count
    assert_equal 0, HasOneNotParanoid.count
  end

  def test_recursive_recovery_dependant_window
    setup_recursive_tests

    @paranoid_time_object.destroy
    @paranoid_time_object.reload

    # Stop the following from recovering:
    #   - ParanoidHasManyDependant and its ParanoidBelongsDependant
    #   - A single ParanoidBelongsDependant, but not its parent
    dependants = @paranoid_time_object.paranoid_has_many_dependants.with_deleted
    dependants.first.update_attribute(:deleted_at, 2.days.ago)
    ParanoidBelongsDependant.with_deleted.where(:id => dependants.last.paranoid_belongs_dependant_id).first.update_attribute(:deleted_at, 1.hour.ago)

    @paranoid_time_object.recover(:recursive => true)

    assert_equal 3, ParanoidTime.count
    assert_equal 2, ParanoidHasManyDependant.count
    assert_equal 1, ParanoidBelongsDependant.count
    assert_equal @paranoid_boolean_count + 3, ParanoidBoolean.count
    assert_equal 3, ParanoidHasOneDependant.count
    assert_equal 1, NotParanoid.count
    assert_equal 0, HasOneNotParanoid.count
  end

  def test_recursive_recovery_for_belongs_to_polymorphic
    child_1 = ParanoidAndroid.create
    section_1 = ParanoidSection.create(:paranoid_thing => child_1)

    child_2 = ParanoidHuman.create(:gender => 'male')
    section_2 = ParanoidSection.create(:paranoid_thing => child_2)

    assert_equal section_1.paranoid_thing, child_1
    assert_equal section_1.paranoid_thing.class, ParanoidAndroid
    assert_equal section_2.paranoid_thing, child_2
    assert_equal section_2.paranoid_thing.class, ParanoidHuman

    parent = ParanoidTime.create(:name => "paranoid_parent")
    parent.paranoid_sections << section_1
    parent.paranoid_sections << section_2

    assert_equal 4, ParanoidTime.count
    assert_equal 2, ParanoidSection.count
    assert_equal 1, ParanoidAndroid.count
    assert_equal 1, ParanoidHuman.count

    parent.destroy

    assert_equal 3, ParanoidTime.count
    assert_equal 0, ParanoidSection.count
    assert_equal 0, ParanoidAndroid.count
    assert_equal 0, ParanoidHuman.count

    parent.reload
    parent.recover

    assert_equal 4, ParanoidTime.count
    assert_equal 2, ParanoidSection.count
    assert_equal 1, ParanoidAndroid.count
    assert_equal 1, ParanoidHuman.count
  end

  def test_non_recursive_recovery
    setup_recursive_tests

    @paranoid_time_object.destroy
    @paranoid_time_object.reload

    @paranoid_time_object.recover(:recursive => false)

    assert_equal 3, ParanoidTime.count
    assert_equal 0, ParanoidHasManyDependant.count
    assert_equal 0, ParanoidBelongsDependant.count
    assert_equal @paranoid_boolean_count, ParanoidBoolean.count
    assert_equal 0, ParanoidHasOneDependant.count
    assert_equal 1, NotParanoid.count
    assert_equal 0, HasOneNotParanoid.count
  end

  def test_deleted?
    ParanoidTime.first.destroy
    assert ParanoidTime.with_deleted.first.deleted?

    ParanoidString.first.destroy
    assert ParanoidString.with_deleted.first.deleted?
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

  def test_recovery_callbacks
    @paranoid_with_callback = ParanoidWithCallback.first

    ParanoidWithCallback.transaction do
      @paranoid_with_callback.destroy

      assert_nil @paranoid_with_callback.called_before_recover
      assert_nil @paranoid_with_callback.called_after_recover

      @paranoid_with_callback.recover
    end

    assert @paranoid_with_callback.called_before_recover
    assert @paranoid_with_callback.called_after_recover
  end

  def test_delete_by_multiple_id_is_paranoid
    model_a = ParanoidBelongsDependant.create
    model_b = ParanoidBelongsDependant.create
    ParanoidBelongsDependant.delete([model_a.id, model_b.id])

    assert_paranoid_deletion(model_a)
    assert_paranoid_deletion(model_b)
  end

  def test_destroy_by_multiple_id_is_paranoid
    model_a = ParanoidBelongsDependant.create
    model_b = ParanoidBelongsDependant.create
    ParanoidBelongsDependant.destroy([model_a.id, model_b.id])

    assert_paranoid_deletion(model_a)
    assert_paranoid_deletion(model_b)
  end

  def test_delete_by_single_id_is_paranoid
    model = ParanoidBelongsDependant.create
    ParanoidBelongsDependant.delete(model.id)

    assert_paranoid_deletion(model)
  end

  def test_destroy_by_single_id_is_paranoid
    model = ParanoidBelongsDependant.create
    ParanoidBelongsDependant.destroy(model.id)

    assert_paranoid_deletion(model)
  end

  def test_instance_delete_is_paranoid
    model = ParanoidBelongsDependant.create
    model.delete

    assert_paranoid_deletion(model)
  end

  def test_instance_destroy_is_paranoid
    model = ParanoidBelongsDependant.create
    model.destroy

    assert_paranoid_deletion(model)
  end

  # Test string type columns that don't have a nil value when not deleted (Y/N for example)
  def test_string_type_with_no_nil_value_before_destroy
    ps = ParanoidString.create!(:deleted => 'not dead')
    assert_equal 1, ParanoidString.where(:id => ps).count
  end

  def test_string_type_with_no_nil_value_after_destroy
    ps = ParanoidString.create!(:deleted => 'not dead')
    ps.destroy
    assert_equal 0, ParanoidString.where(:id => ps).count
  end

  def test_string_type_with_no_nil_value_before_destroy_with_deleted
    ps = ParanoidString.create!(:deleted => 'not dead')
    assert_equal 1, ParanoidString.with_deleted.where(:id => ps).count
  end

  def test_string_type_with_no_nil_value_after_destroy_with_deleted
    ps = ParanoidString.create!(:deleted => 'not dead')
    ps.destroy
    assert_equal 1, ParanoidString.with_deleted.where(:id => ps).count
  end

  def test_string_type_with_no_nil_value_before_destroy_only_deleted
    ps = ParanoidString.create!(:deleted => 'not dead')
    assert_equal 0, ParanoidString.only_deleted.where(:id => ps).count
  end

  def test_string_type_with_no_nil_value_after_destroy_only_deleted
    ps = ParanoidString.create!(:deleted => 'not dead')
    ps.destroy
    assert_equal 1, ParanoidString.only_deleted.where(:id => ps).count
  end

  def test_string_type_with_no_nil_value_after_destroyed_twice
    ps = ParanoidString.create!(:deleted => 'not dead')
    2.times { ps.destroy }
    assert_equal 0, ParanoidString.with_deleted.where(:id => ps).count
  end

  # Test boolean type columns, that are not nullable
  def test_boolean_type_with_no_nil_value_before_destroy
    ps = ParanoidBooleanNotNullable.create!()
    assert_equal 1, ParanoidBooleanNotNullable.where(:id => ps).count
  end

  def test_boolean_type_with_no_nil_value_after_destroy
    ps = ParanoidBooleanNotNullable.create!()
    ps.destroy
    assert_equal 0, ParanoidBooleanNotNullable.where(:id => ps).count
  end

  def test_boolean_type_with_no_nil_value_before_destroy_with_deleted
    ps = ParanoidBooleanNotNullable.create!()
    assert_equal 1, ParanoidBooleanNotNullable.with_deleted.where(:id => ps).count
  end

  def test_boolean_type_with_no_nil_value_after_destroy_with_deleted
    ps = ParanoidBooleanNotNullable.create!()
    ps.destroy
    assert_equal 1, ParanoidBooleanNotNullable.with_deleted.where(:id => ps).count
  end

  def test_boolean_type_with_no_nil_value_before_destroy_only_deleted
    ps = ParanoidBooleanNotNullable.create!()
    assert_equal 0, ParanoidBooleanNotNullable.only_deleted.where(:id => ps).count
  end

  def test_boolean_type_with_no_nil_value_after_destroy_only_deleted
    ps = ParanoidBooleanNotNullable.create!()
    ps.destroy
    assert_equal 1, ParanoidBooleanNotNullable.only_deleted.where(:id => ps).count
  end

  def test_boolean_type_with_no_nil_value_after_destroyed_twice
    ps = ParanoidBooleanNotNullable.create!()
    2.times { ps.destroy }
    assert_equal 0, ParanoidBooleanNotNullable.with_deleted.where(:id => ps).count
  end
end
