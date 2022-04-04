# frozen_string_literal: true

require "test_helper"

class AssociationsTest < ActiveSupport::TestCase
  class ParanoidManyManyParentLeft < ActiveRecord::Base
    has_many :paranoid_many_many_children
    has_many :paranoid_many_many_parent_rights, through: :paranoid_many_many_children
  end

  class ParanoidManyManyParentRight < ActiveRecord::Base
    has_many :paranoid_many_many_children
    has_many :paranoid_many_many_parent_lefts, through: :paranoid_many_many_children
  end

  class ParanoidManyManyChild < ActiveRecord::Base
    acts_as_paranoid
    belongs_to :paranoid_many_many_parent_left
    belongs_to :paranoid_many_many_parent_right
  end

  class ParanoidDestroyCompany < ActiveRecord::Base
    acts_as_paranoid
    validates :name, presence: true
    has_many :paranoid_products, dependent: :destroy
  end

  class ParanoidDeleteCompany < ActiveRecord::Base
    acts_as_paranoid
    validates :name, presence: true
    has_many :paranoid_products, dependent: :delete_all
  end

  class ParanoidProduct < ActiveRecord::Base
    acts_as_paranoid
    belongs_to :paranoid_destroy_company
    belongs_to :paranoid_delete_company
    validates_presence_of :name
  end

  class ParanoidBelongsToPolymorphic < ActiveRecord::Base
    acts_as_paranoid
    belongs_to :parent, polymorphic: true, with_deleted: true
  end

  class NotParanoidHasManyAsParent < ActiveRecord::Base
    has_many :paranoid_belongs_to_polymorphics, as: :parent, dependent: :destroy
  end

  class ParanoidHasManyAsParent < ActiveRecord::Base
    acts_as_paranoid
    has_many :paranoid_belongs_to_polymorphics, as: :parent, dependent: :destroy
  end

  class ParanoidHasManyDependant < ActiveRecord::Base
    acts_as_paranoid
    belongs_to :paranoid_time
    belongs_to :paranoid_time_with_scope,
               -> { where(name: "hello").includes(:not_paranoid) },
               class_name: "ParanoidTime", foreign_key: :paranoid_time_id
    belongs_to :paranoid_time_with_deleted, class_name: "ParanoidTime",
                                            foreign_key: :paranoid_time_id,
                                            with_deleted: true
    belongs_to :paranoid_time_with_scope_with_deleted,
               -> { where(name: "hello").includes(:not_paranoid) },
               class_name: "ParanoidTime", foreign_key: :paranoid_time_id,
               with_deleted: true
    belongs_to :paranoid_time_polymorphic_with_deleted, class_name: "ParanoidTime",
                                                        foreign_key: :paranoid_time_id,
                                                        polymorphic: true,
                                                        with_deleted: true

    belongs_to :paranoid_belongs_dependant, dependent: :destroy
  end

  class ParanoidBelongsDependant < ActiveRecord::Base
    acts_as_paranoid

    has_many :paranoid_has_many_dependants
  end

  class ParanoidTime < ActiveRecord::Base
    acts_as_paranoid

    validates_uniqueness_of :name

    has_many :paranoid_has_many_dependants, dependent: :destroy
    has_many :paranoid_booleans, dependent: :destroy
    has_many :not_paranoids, dependent: :delete_all
    # has_many :paranoid_sections, dependent: :destroy

    has_one :has_one_not_paranoid, dependent: :destroy

    belongs_to :not_paranoid, dependent: :destroy

    attr_accessor :destroyable

    before_destroy :ensure_destroyable

    protected

    def ensure_destroyable
      return if destroyable.nil?

      throw(:abort) unless destroyable
    end
  end

  class ParanoidBoolean < ActiveRecord::Base
    acts_as_paranoid column_type: "boolean", column: "is_deleted"
    validates_as_paranoid
    validates_uniqueness_of_without_deleted :name

    belongs_to :paranoid_time
    has_one :paranoid_has_one_dependant, dependent: :destroy
    has_many :paranoid_with_counter_cache, dependent: :destroy
    has_many :paranoid_with_custom_counter_cache, dependent: :destroy
    has_many :paranoid_with_touch_and_counter_cache, dependent: :destroy
    has_many :paranoid_with_touch, dependent: :destroy
  end

  class NotParanoid < ActiveRecord::Base
    has_many :paranoid_times
  end

  class HasOneNotParanoid < ActiveRecord::Base
    belongs_to :paranoid_time, with_deleted: true
  end

  class DoubleHasOneNotParanoid < HasOneNotParanoid
    belongs_to :paranoid_time, with_deleted: true
    begin
      verbose = $VERBOSE
      $VERBOSE = false
      belongs_to :paranoid_time, with_deleted: true
    ensure
      $VERBOSE = verbose
    end
  end

  # rubocop:disable Metrics/AbcSize
  def setup
    ActiveRecord::Schema.define(version: 1) do # rubocop:disable Metrics/BlockLength
      create_table :paranoid_many_many_parent_lefts do |t|
        t.string :name
        timestamps t
      end

      create_table :paranoid_many_many_parent_rights do |t|
        t.string :name
        timestamps t
      end

      create_table :paranoid_many_many_children do |t|
        t.integer :paranoid_many_many_parent_left_id
        t.integer :paranoid_many_many_parent_right_id
        t.datetime :deleted_at
        timestamps t
      end

      create_table :paranoid_has_many_dependants do |t|
        t.string    :name
        t.datetime  :deleted_at
        t.integer   :paranoid_time_id
        t.string    :paranoid_time_polymorphic_with_deleted_type
        t.integer   :paranoid_belongs_dependant_id

        timestamps t
      end

      create_table :paranoid_belongs_dependants do |t|
        t.string    :name
        t.datetime  :deleted_at

        timestamps t
      end

      create_table :paranoid_destroy_companies do |t|
        t.string :name
        t.datetime :deleted_at

        timestamps t
      end

      create_table :paranoid_delete_companies do |t|
        t.string :name
        t.datetime :deleted_at

        timestamps t
      end

      create_table :paranoid_products do |t|
        t.integer :paranoid_destroy_company_id
        t.integer :paranoid_delete_company_id
        t.string :name
        t.datetime :deleted_at

        timestamps t
      end

      create_table :paranoid_times do |t|
        t.string    :name
        t.datetime  :deleted_at
        t.integer   :paranoid_belongs_dependant_id
        t.integer   :not_paranoid_id

        timestamps t
      end

      create_table :paranoid_booleans do |t|
        t.string    :name
        t.boolean   :is_deleted
        t.integer   :paranoid_time_id
        t.integer   :paranoid_with_counter_caches_count
        t.integer   :paranoid_with_touch_and_counter_caches_count
        t.integer   :custom_counter_cache
        timestamps t
      end

      create_table :not_paranoid_has_many_as_parents do |t|
        t.string :name

        timestamps t
      end

      create_table :paranoid_has_many_as_parents do |t|
        t.string :name
        t.datetime :deleted_at

        timestamps t
      end

      create_table :not_paranoids do |t|
        t.string    :name
        t.integer   :paranoid_time_id

        timestamps t
      end

      create_table :has_one_not_paranoids do |t|
        t.string    :name
        t.integer   :paranoid_time_id

        timestamps t
      end

      create_table :paranoid_belongs_to_polymorphics do |t|
        t.string :name
        t.string :parent_type
        t.integer :parent_id
        t.datetime :deleted_at

        timestamps t
      end
    end
  end
  # rubocop:enable Metrics/AbcSize

  def teardown
    teardown_db
  end

  def test_removal_with_destroy_associations
    paranoid_company = ParanoidDestroyCompany.create! name: "ParanoidDestroyCompany #1"
    paranoid_company.paranoid_products.create! name: "ParanoidProduct #1"

    assert_equal 1, ParanoidDestroyCompany.count
    assert_equal 1, ParanoidProduct.count

    ParanoidDestroyCompany.first.destroy
    assert_equal 0, ParanoidDestroyCompany.count
    assert_equal 0, ParanoidProduct.count
    assert_equal 1, ParanoidDestroyCompany.with_deleted.count
    assert_equal 1, ParanoidProduct.with_deleted.count

    ParanoidDestroyCompany.with_deleted.first.destroy
    assert_equal 0, ParanoidDestroyCompany.count
    assert_equal 0, ParanoidProduct.count
    assert_equal 0, ParanoidDestroyCompany.with_deleted.count
    assert_equal 0, ParanoidProduct.with_deleted.count
  end

  def test_removal_with_delete_all_associations
    paranoid_company = ParanoidDeleteCompany.create! name: "ParanoidDestroyCompany #1"
    paranoid_company.paranoid_products.create! name: "ParanoidProduct #2"

    assert_equal 1, ParanoidDeleteCompany.count
    assert_equal 1, ParanoidProduct.count

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
    paranoid_time = ParanoidTime.create! name: "paranoid"
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
    paranoid_time = ParanoidTime.create! name: "paranoid"
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
    paranoid_time = ParanoidTime.create! name: "paranoid"
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

    assert_empty parent.paranoid_has_many_dependants.to_a
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
    assert_predicate obj, :destroyed?

    assert_empty ParanoidHasManyDependant.with_deleted.joins(:paranoid_time)
    assert_equal [obj],
                 ParanoidHasManyDependant.with_deleted.joins(:paranoid_time_with_deleted)
  end

  def test_includes_with_deleted
    paranoid_time = ParanoidTime.create! name: "paranoid"
    paranoid_time.paranoid_has_many_dependants.create(name: "dependant!")

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

    assert_empty left.paranoid_many_many_children, "Linking objects not deleted"
    assert_empty left.paranoid_many_many_parent_rights,
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

    assert_empty left.paranoid_many_many_children, "Linking objects not deleted"
    assert_empty left.paranoid_many_many_parent_rights,
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

    assert_empty left.paranoid_many_many_parent_rights, "Associated objects not deleted"
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

  def test_mass_assignment_of_paranoid_column_disabled
    assert_raises ActiveRecord::RecordNotSaved do
      ParanoidTime.create! name: "Foo", deleted_at: Time.now
    end
  end
end
