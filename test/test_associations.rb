# frozen_string_literal: true

require "test_helper"

class AssociationsTest < ParanoidBaseTest
  def test_removal_with_associations
    paranoid_company_1 = ParanoidDestroyCompany.create! name: "ParanoidDestroyCompany #1"
    paranoid_company_2 = ParanoidDeleteCompany.create! name: "ParanoidDestroyCompany #1"
    paranoid_company_1.paranoid_products.create! name: "ParanoidProduct #1"
    paranoid_company_2.paranoid_products.create! name: "ParanoidProduct #2"

    assert_equal 1, ParanoidDestroyCompany.count
    assert_equal 1, ParanoidDeleteCompany.count
    assert_equal 2, ParanoidProduct.count

    ParanoidDestroyCompany.first.destroy
    assert_equal 0, ParanoidDestroyCompany.count
    assert_equal 1, ParanoidProduct.count
    assert_equal 1, ParanoidDestroyCompany.with_deleted.count
    assert_equal 2, ParanoidProduct.with_deleted.count

    ParanoidDestroyCompany.with_deleted.first.destroy
    assert_equal 0, ParanoidDestroyCompany.count
    assert_equal 1, ParanoidProduct.count
    assert_equal 0, ParanoidDestroyCompany.with_deleted.count
    assert_equal 1, ParanoidProduct.with_deleted.count

    ParanoidDeleteCompany.first.destroy
    assert_equal 0, ParanoidDeleteCompany.count
    assert_equal 0, ParanoidProduct.count
    assert_equal 1, ParanoidDeleteCompany.with_deleted.count
    assert_equal 1, ParanoidProduct.with_deleted.count

    ParanoidDeleteCompany.with_deleted.first.destroy
    assert_equal 0, ParanoidDeleteCompany.count
    assert_equal 0, ParanoidProduct.count
    assert_equal 0, ParanoidDeleteCompany.with_deleted.count
    assert_equal 0, ParanoidProduct.with_deleted.count
  end

  def test_belongs_to_with_scope_option
    paranoid_has_many_dependant = ParanoidHasManyDependant.new

    expected_includes_values = ParanoidTime.includes(:not_paranoid).includes_values
    includes_values = paranoid_has_many_dependant
      .association(:paranoid_time_with_scope).scope.includes_values

    assert_equal expected_includes_values, includes_values

    paranoid_time = ParanoidTime.create(name: "not-hello")
    paranoid_has_many_dependant.paranoid_time = paranoid_time
    paranoid_has_many_dependant.save!

    assert_nil paranoid_has_many_dependant.paranoid_time_with_scope

    paranoid_time.update(name: "hello")

    paranoid_has_many_dependant.reload

    assert_equal paranoid_time, paranoid_has_many_dependant.paranoid_time_with_scope

    paranoid_time.destroy

    paranoid_has_many_dependant.reload

    assert_nil paranoid_has_many_dependant.paranoid_time_with_scope
  end

  def test_belongs_to_with_scope_and_deleted_option
    paranoid_has_many_dependant = ParanoidHasManyDependant.new
    includes_values = ParanoidTime.includes(:not_paranoid).includes_values

    assert_equal includes_values, paranoid_has_many_dependant
      .association(:paranoid_time_with_scope_with_deleted).scope.includes_values

    paranoid_time = ParanoidTime.create(name: "not-hello")
    paranoid_has_many_dependant.paranoid_time = paranoid_time
    paranoid_has_many_dependant.save!

    assert_nil paranoid_has_many_dependant.paranoid_time_with_scope_with_deleted

    paranoid_time.update(name: "hello")
    paranoid_has_many_dependant.reload

    assert_equal paranoid_time, paranoid_has_many_dependant
      .paranoid_time_with_scope_with_deleted

    paranoid_time.destroy
    paranoid_has_many_dependant.reload

    assert_equal paranoid_time, paranoid_has_many_dependant
      .paranoid_time_with_scope_with_deleted
  end

  def test_belongs_to_with_deleted
    paranoid_time = ParanoidTime.first
    paranoid_has_many_dependant = paranoid_time.paranoid_has_many_dependants
      .create(name: "dependant!")

    assert_equal paranoid_time, paranoid_has_many_dependant.paranoid_time
    assert_equal paranoid_time, paranoid_has_many_dependant.paranoid_time_with_deleted

    paranoid_time.destroy
    paranoid_has_many_dependant.reload

    assert_nil paranoid_has_many_dependant.paranoid_time
    assert_equal paranoid_time, paranoid_has_many_dependant.paranoid_time_with_deleted
  end

  def test_belongs_to_polymorphic_with_deleted
    paranoid_time = ParanoidTime.first
    paranoid_has_many_dependant = ParanoidHasManyDependant
      .create!(name: "dependant!", paranoid_time_polymorphic_with_deleted: paranoid_time)

    assert_equal paranoid_time, paranoid_has_many_dependant.paranoid_time
    assert_equal paranoid_time, paranoid_has_many_dependant
      .paranoid_time_polymorphic_with_deleted

    paranoid_time.destroy

    assert_nil paranoid_has_many_dependant.reload.paranoid_time
    assert_equal paranoid_time, paranoid_has_many_dependant
      .reload.paranoid_time_polymorphic_with_deleted
  end

  def test_belongs_to_nil_polymorphic_with_deleted
    paranoid_time = ParanoidTime.first
    paranoid_has_many_dependant =
      ParanoidHasManyDependant.create!(name: "dependant!",
                                       paranoid_time_polymorphic_with_deleted: nil)

    assert_nil paranoid_has_many_dependant.paranoid_time
    assert_nil paranoid_has_many_dependant.paranoid_time_polymorphic_with_deleted

    paranoid_time.destroy

    assert_nil paranoid_has_many_dependant.reload.paranoid_time
    assert_nil paranoid_has_many_dependant.reload.paranoid_time_polymorphic_with_deleted
  end

  def test_belongs_to_options
    paranoid_time = ParanoidHasManyDependant.reflections
      .with_indifferent_access[:paranoid_time]
    assert_equal :belongs_to, paranoid_time.macro
    assert_nil paranoid_time.options[:with_deleted]
  end

  def test_belongs_to_with_deleted_options
    paranoid_time_with_deleted =
      ParanoidHasManyDependant.reflections
        .with_indifferent_access[:paranoid_time_with_deleted]
    assert_equal :belongs_to, paranoid_time_with_deleted.macro
    assert paranoid_time_with_deleted.options[:with_deleted]
  end

  def test_belongs_to_polymorphic_with_deleted_options
    paranoid_time_polymorphic_with_deleted = ParanoidHasManyDependant.reflections
      .with_indifferent_access[:paranoid_time_polymorphic_with_deleted]
    assert_equal :belongs_to, paranoid_time_polymorphic_with_deleted.macro
    assert paranoid_time_polymorphic_with_deleted.options[:with_deleted]
  end

  def test_only_find_associated_records_when_finding_with_paranoid_deleted
    parent = ParanoidBelongsDependant.create
    child = ParanoidHasManyDependant.create
    parent.paranoid_has_many_dependants << child

    unrelated_parent = ParanoidBelongsDependant.create
    unrelated_child = ParanoidHasManyDependant.create
    unrelated_parent.paranoid_has_many_dependants << unrelated_child

    child.destroy
    assert_paranoid_deletion(child)

    parent.reload

    assert_equal [], parent.paranoid_has_many_dependants.to_a
    assert_equal [child], parent.paranoid_has_many_dependants.with_deleted.to_a
  end

  def test_join_with_model_with_deleted
    obj = ParanoidHasManyDependant.create(paranoid_time: ParanoidTime.create)
    assert_not_nil obj.paranoid_time
    assert_not_nil obj.paranoid_time_with_deleted

    obj.paranoid_time.destroy
    obj.reload

    assert_nil obj.paranoid_time
    assert_not_nil obj.paranoid_time_with_deleted

    # Note that obj is destroyed because of dependent: :destroy in ParanoidTime
    assert obj.destroyed?

    assert_empty ParanoidHasManyDependant.with_deleted.joins(:paranoid_time)
    assert_equal [obj],
                 ParanoidHasManyDependant.with_deleted.joins(:paranoid_time_with_deleted)
  end

  def test_includes_with_deleted
    paranoid_time = ParanoidTime.first
    paranoid_has_many_dependant = paranoid_time.paranoid_has_many_dependants
      .create(name: "dependant!")

    paranoid_time.destroy

    ParanoidHasManyDependant.with_deleted
      .includes(:paranoid_time_with_deleted).each do |hasmany|
      assert_not_nil hasmany.paranoid_time_with_deleted
    end
  end

  def test_includes_with_deleted_with_polymorphic_parent
    not_paranoid_parent = NotParanoidHasManyAsParent.create(name: "not paranoid parent")
    paranoid_parent = ParanoidHasManyAsParent.create(name: "paranoid parent")
    ParanoidBelongsToPolymorphic.create(name: "belongs_to", parent: not_paranoid_parent)
    ParanoidBelongsToPolymorphic.create(name: "belongs_to", parent: paranoid_parent)

    paranoid_parent.destroy

    ParanoidBelongsToPolymorphic.with_deleted.includes(:parent).each do |hasmany|
      assert_not_nil hasmany.parent
    end
  end

  def test_cannot_find_a_paranoid_deleted_many_many_association
    left = ParanoidManyManyParentLeft.create
    right = ParanoidManyManyParentRight.create
    left.paranoid_many_many_parent_rights << right

    left.paranoid_many_many_parent_rights.delete(right)

    left.reload

    assert_equal [], left.paranoid_many_many_children, "Linking objects not deleted"
    assert_equal [], left.paranoid_many_many_parent_rights,
                 "Associated objects not unlinked"
    assert_equal right, ParanoidManyManyParentRight.find(right.id),
                 "Associated object deleted"
  end

  def test_cannot_find_a_paranoid_destroyed_many_many_association
    left = ParanoidManyManyParentLeft.create
    right = ParanoidManyManyParentRight.create
    left.paranoid_many_many_parent_rights << right

    left.paranoid_many_many_parent_rights.destroy(right)

    left.reload

    assert_equal [], left.paranoid_many_many_children, "Linking objects not deleted"
    assert_equal [], left.paranoid_many_many_parent_rights,
                 "Associated objects not unlinked"
    assert_equal right, ParanoidManyManyParentRight.find(right.id),
                 "Associated object deleted"
  end

  def test_cannot_find_a_has_many_through_object_when_its_linking_object_is_soft_destroyed
    left = ParanoidManyManyParentLeft.create
    right = ParanoidManyManyParentRight.create
    left.paranoid_many_many_parent_rights << right

    child = left.paranoid_many_many_children.first

    child.destroy

    left.reload

    assert_equal [], left.paranoid_many_many_parent_rights, "Associated objects not deleted"
  end

  def test_cannot_find_a_paranoid_deleted_model
    model = ParanoidBelongsDependant.create
    model.destroy

    assert_raises ActiveRecord::RecordNotFound do
      ParanoidBelongsDependant.find(model.id)
    end
  end

  def test_bidirectional_has_many_through_association_clear_is_paranoid
    left = ParanoidManyManyParentLeft.create
    right = ParanoidManyManyParentRight.create
    left.paranoid_many_many_parent_rights << right

    child = left.paranoid_many_many_children.first
    assert_equal left, child.paranoid_many_many_parent_left,
                 "Child's left parent is incorrect"
    assert_equal right, child.paranoid_many_many_parent_right,
                 "Child's right parent is incorrect"

    left.paranoid_many_many_parent_rights.clear

    assert_paranoid_deletion(child)
  end

  def test_bidirectional_has_many_through_association_destroy_is_paranoid
    left = ParanoidManyManyParentLeft.create
    right = ParanoidManyManyParentRight.create
    left.paranoid_many_many_parent_rights << right

    child = left.paranoid_many_many_children.first
    assert_equal left, child.paranoid_many_many_parent_left,
                 "Child's left parent is incorrect"
    assert_equal right, child.paranoid_many_many_parent_right,
                 "Child's right parent is incorrect"

    left.paranoid_many_many_parent_rights.destroy(right)

    assert_paranoid_deletion(child)
  end

  def test_bidirectional_has_many_through_association_delete_is_paranoid
    left = ParanoidManyManyParentLeft.create
    right = ParanoidManyManyParentRight.create
    left.paranoid_many_many_parent_rights << right

    child = left.paranoid_many_many_children.first
    assert_equal left, child.paranoid_many_many_parent_left,
                 "Child's left parent is incorrect"
    assert_equal right, child.paranoid_many_many_parent_right,
                 "Child's right parent is incorrect"

    left.paranoid_many_many_parent_rights.delete(right)

    assert_paranoid_deletion(child)
  end

  def test_belongs_to_on_normal_model_is_paranoid
    not_paranoid = HasOneNotParanoid.create
    not_paranoid.paranoid_time = ParanoidTime.create

    assert not_paranoid.save
    assert_not_nil not_paranoid.paranoid_time
  end

  def test_double_belongs_to_with_deleted
    not_paranoid = DoubleHasOneNotParanoid.create
    not_paranoid.paranoid_time = ParanoidTime.create

    assert not_paranoid.save
    assert_not_nil not_paranoid.paranoid_time
  end

  def test_mass_assignment_of_paranoid_column_enabled
    if Gem.loaded_specs["activerecord"].version >= Gem::Version.new("5.2.0")
      skip "Creation as deleted is not supported with Rails >= 5.2"
    end
    now = Time.now
    record = ParanoidTime.create! name: "Foo", deleted_at: now
    assert_equal "Foo", record.name
    assert_equal now, record.deleted_at
  end
end
