require 'test_helper'

class ParanoidTest < ParanoidBaseTest
  def test_paranoid?
    assert !NotParanoid.paranoid?
    assert_raise(NoMethodError) { NotParanoid.delete_all! }
    assert_raise(NoMethodError) { NotParanoid.first.destroy! }
    assert_raise(NoMethodError) { NotParanoid.with_deleted }
    assert_raise(NoMethodError) { NotParanoid.only_deleted }    

    assert ParanoidTime.paranoid?
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
    ParanoidTime.first.destroy!
    ParanoidBoolean.delete_all!("name = 'extremely paranoid' OR name = 'really paranoid'")
    ParanoidString.first.destroy!
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
    assert_empty ParanoidTime.with_deleted.all
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
end

class MultipleDefaultScopesTest < ParanoidBaseTest
  def setup
    setup_db

    # Naturally, the default scope for humans is male. Sexism++
    ParanoidHuman.create! :gender => 'male'
    ParanoidHuman.create! :gender => 'male'
    ParanoidHuman.create! :gender => 'male'
    ParanoidHuman.create! :gender => 'female'

    assert_equal 3, ParanoidHuman.count
    assert_equal 4, ParanoidHuman.unscoped.count
  end

  def test_fake_removal_with_multiple_default_scope
    ParanoidHuman.first.destroy
    assert_equal 2, ParanoidHuman.count
    assert_equal 3, ParanoidHuman.with_deleted.count
    assert_equal 1, ParanoidHuman.only_deleted.count
    assert_equal 4, ParanoidHuman.unscoped.count

    ParanoidHuman.destroy_all
    assert_equal 0, ParanoidHuman.count
    assert_equal 3, ParanoidHuman.with_deleted.count
    assert_equal 3, ParanoidHuman.with_deleted.count
    assert_equal 4, ParanoidHuman.unscoped.count
  end
  
  def test_real_removal_with_multiple_default_scope
    # two-step
    ParanoidHuman.first.destroy
    ParanoidHuman.only_deleted.first.destroy
    assert_equal 2, ParanoidHuman.count
    assert_equal 2, ParanoidHuman.with_deleted.count
    assert_equal 0, ParanoidHuman.only_deleted.count
    assert_equal 3, ParanoidHuman.unscoped.count

    ParanoidHuman.first.destroy!
    assert_equal 1, ParanoidHuman.count
    assert_equal 1, ParanoidHuman.with_deleted.count
    assert_equal 0, ParanoidHuman.only_deleted.count
    assert_equal 2, ParanoidHuman.unscoped.count

    ParanoidHuman.delete_all!
    assert_equal 0, ParanoidHuman.count
    assert_equal 0, ParanoidHuman.with_deleted.count
    assert_equal 0, ParanoidHuman.only_deleted.count
    assert_equal 1, ParanoidHuman.unscoped.count
  end
end

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
    ParanoidForest.rainforest.destroy(@paranoid_forest_3)
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
    @paranoid_forest_1.paranoid_trees.order(:id).destroy(paranoid_tree)
    @paranoid_forest_1.paranoid_trees.only_deleted.destroy(paranoid_tree)
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

class ValidatesUniquenessTest < ParanoidBaseTest
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

class AssociationsTest < ParanoidBaseTest  
  def test_removal_with_associations
    # This test shows that the current implementation doesn't handle
    # assciation deletion correctly (when hard deleting via parent-object)
    paranoid_company_1 = ParanoidDestroyCompany.create! :name => "ParanoidDestroyCompany #1"
    paranoid_company_2 = ParanoidDeleteCompany.create! :name => "ParanoidDestroyCompany #1"
    paranoid_company_1.paranoid_products.create! :name => "ParanoidProduct #1"
    paranoid_company_2.paranoid_products.create! :name => "ParanoidProduct #2"
    
    assert_equal 1, ParanoidDestroyCompany.count
    assert_equal 1, ParanoidDeleteCompany.count
    assert_equal 2, ParanoidProduct.count

    ParanoidDestroyCompany.first.destroy
    assert_equal 0, ParanoidDestroyCompany.count
    assert_equal 1, ParanoidProduct.count
    assert_equal 1, ParanoidDestroyCompany.with_deleted.count
    assert_equal 2, ParanoidProduct.with_deleted.count
  
    ParanoidDestroyCompany.with_deleted.first.destroy!
    assert_equal 0, ParanoidDestroyCompany.count
    assert_equal 1, ParanoidProduct.count
    assert_equal 0, ParanoidDestroyCompany.with_deleted.count
    assert_equal 1, ParanoidProduct.with_deleted.count
    
    ParanoidDeleteCompany.with_deleted.first.destroy!
    assert_equal 0, ParanoidDeleteCompany.count
    assert_equal 0, ParanoidProduct.count
    assert_equal 0, ParanoidDeleteCompany.with_deleted.count
    assert_equal 0, ParanoidProduct.with_deleted.count
  end

  def test_belongs_to_with_deleted
    paranoid_time = ParanoidTime.first 
    paranoid_has_many_dependant = paranoid_time.paranoid_has_many_dependants.create(:name => 'dependant!')

    assert paranoid_has_many_dependant.paranoid_time
    assert paranoid_has_many_dependant.paranoid_time_with_deleted

    paranoid_time.destroy
    
    assert_nil paranoid_has_many_dependant.paranoid_time(true)
    assert paranoid_has_many_dependant.paranoid_time_with_deleted(true)
  end

  def test_belongs_to_polymorphic_with_deleted
    paranoid_time = ParanoidTime.first 
    paranoid_has_many_dependant = ParanoidHasManyDependant.create!(:name => 'dependant!', :paranoid_time_polymorphic_with_deleted => paranoid_time)

    assert paranoid_has_many_dependant.paranoid_time
    assert paranoid_has_many_dependant.paranoid_time_polymorphic_with_deleted

    paranoid_time.destroy
    
    assert_nil paranoid_has_many_dependant.paranoid_time(true)
    assert paranoid_has_many_dependant.paranoid_time_polymorphic_with_deleted(true)
  end
end

class InheritanceTest < ParanoidBaseTest
  def test_destroy_dependents_with_inheritance
    has_many_inherited_super_paranoidz = HasManyInheritedSuperParanoidz.new
    has_many_inherited_super_paranoidz.save
    has_many_inherited_super_paranoidz.super_paranoidz.create
    assert_nothing_raised(NoMethodError) { has_many_inherited_super_paranoidz.destroy }
  end
  
  def test_class_instance_variables_are_inherited
    assert_nothing_raised(ActiveRecord::StatementInvalid) { InheritedParanoid.paranoid_column }
  end
end

class ParanoidObserverTest < ParanoidBaseTest

  def test_called_observer_methods
    @subject = ParanoidWithCallback.new
    @subject.save

    assert_nil ParanoidObserver.instance.called_before_recover
    assert_nil ParanoidObserver.instance.called_after_recover
    
    ParanoidWithCallback.find(@subject.id).recover

    assert_equal @subject, ParanoidObserver.instance.called_before_recover
    assert_equal @subject, ParanoidObserver.instance.called_after_recover
  end
end
