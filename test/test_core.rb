# frozen_string_literal: true

require "test_helper"

class ParanoidTest < ActiveSupport::TestCase
  class ParanoidTime < ActiveRecord::Base
    acts_as_paranoid

    validates_uniqueness_of :name

    has_many :paranoid_has_many_dependants, dependent: :destroy
    has_many :paranoid_booleans, dependent: :destroy
    has_many :not_paranoids, dependent: :delete_all
    has_many :paranoid_sections, dependent: :destroy

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

  class ParanoidString < ActiveRecord::Base
    acts_as_paranoid column_type: "string", column: "deleted", deleted_value: "dead"
  end

  class NotParanoid < ActiveRecord::Base
    has_many :paranoid_times
  end

  class ParanoidNoDoubleTapDestroysFully < ActiveRecord::Base
    acts_as_paranoid double_tap_destroys_fully: false
  end

  class HasOneNotParanoid < ActiveRecord::Base
    belongs_to :paranoid_time, with_deleted: true
  end

  class ParanoidWithCounterCache < ActiveRecord::Base
    acts_as_paranoid
    belongs_to :paranoid_boolean, counter_cache: true
  end

  class ParanoidWithCustomCounterCache < ActiveRecord::Base
    self.table_name = "paranoid_with_counter_caches"

    acts_as_paranoid
    belongs_to :paranoid_boolean, counter_cache: :custom_counter_cache
  end

  class ParanoidWithCounterCacheOnOptionalBelognsTo < ActiveRecord::Base
    self.table_name = "paranoid_with_counter_caches"

    acts_as_paranoid
    belongs_to :paranoid_boolean, counter_cache: true, optional: true
  end

  class ParanoidWithTouch < ActiveRecord::Base
    self.table_name = "paranoid_with_counter_caches"
    acts_as_paranoid
    belongs_to :paranoid_boolean, touch: true
  end

  class ParanoidWithTouchAndCounterCache < ActiveRecord::Base
    self.table_name = "paranoid_with_counter_caches"
    acts_as_paranoid
    belongs_to :paranoid_boolean, touch: true, counter_cache: true
  end

  class ParanoidHasManyDependant < ActiveRecord::Base
    acts_as_paranoid

    belongs_to :paranoid_belongs_dependant, dependent: :destroy
  end

  class ParanoidBelongsDependant < ActiveRecord::Base
    acts_as_paranoid

    has_many :paranoid_has_many_dependants
  end

  class ParanoidHasOneDependant < ActiveRecord::Base
    acts_as_paranoid

    belongs_to :paranoid_boolean
  end

  class ParanoidWithCallback < ActiveRecord::Base
    acts_as_paranoid

    attr_accessor :called_before_destroy, :called_after_destroy,
                  :called_after_commit_on_destroy, :called_before_recover,
                  :called_after_recover

    before_destroy :call_me_before_destroy
    after_destroy :call_me_after_destroy

    after_commit :call_me_after_commit_on_destroy, on: :destroy

    before_recover :call_me_before_recover
    after_recover :call_me_after_recover

    def initialize(*attrs)
      @called_before_destroy = false
      @called_after_destroy = false
      @called_after_commit_on_destroy = false
      super
    end

    def call_me_before_destroy
      @called_before_destroy = true
    end

    def call_me_after_destroy
      @called_after_destroy = true
    end

    def call_me_after_commit_on_destroy
      @called_after_commit_on_destroy = true
    end

    def call_me_before_recover
      @called_before_recover = true
    end

    def call_me_after_recover
      @called_after_recover = true
    end
  end

  class ParanoidPolygon < ActiveRecord::Base
    acts_as_paranoid
    default_scope { where("sides = ?", 3) }
  end

  class ParanoidAndroid < ActiveRecord::Base
    acts_as_paranoid
  end

  class ParanoidSection < ActiveRecord::Base
    acts_as_paranoid
    belongs_to :paranoid_time
    belongs_to :paranoid_thing, polymorphic: true, dependent: :destroy
  end

  class ParanoidBooleanNotNullable < ActiveRecord::Base
    acts_as_paranoid column: "deleted", column_type: "boolean", allow_nulls: false
  end

  class ParanoidWithExplicitTableNameAfterMacro < ActiveRecord::Base
    acts_as_paranoid
    self.table_name = "explicit_table"
  end

  # rubocop:disable Metrics/AbcSize
  def setup_db
    ActiveRecord::Schema.define(version: 1) do # rubocop:disable Metrics/BlockLength
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

      create_table :paranoid_strings do |t|
        t.string    :name
        t.string    :deleted
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

      create_table :paranoid_has_one_dependants do |t|
        t.string    :name
        t.datetime  :deleted_at
        t.integer   :paranoid_boolean_id

        timestamps t
      end

      create_table :paranoid_with_callbacks do |t|
        t.string    :name
        t.datetime  :deleted_at

        timestamps t
      end

      create_table :paranoid_polygons do |t|
        t.integer :sides
        t.datetime :deleted_at

        timestamps t
      end

      create_table :paranoid_androids do |t|
        t.datetime :deleted_at
      end

      create_table :paranoid_sections do |t|
        t.integer   :paranoid_time_id
        t.integer   :paranoid_thing_id
        t.string    :paranoid_thing_type
        t.datetime :deleted_at
      end

      create_table :paranoid_boolean_not_nullables do |t|
        t.string :name
        t.boolean :deleted, :boolean, null: false, default: false
      end

      create_table :paranoid_no_double_tap_destroys_fullies do |t|
        t.datetime :deleted_at
      end

      create_table :paranoid_with_counter_caches do |t|
        t.string    :name
        t.datetime  :deleted_at
        t.integer   :paranoid_boolean_id

        timestamps t
      end
    end
  end
  # rubocop:enable Metrics/AbcSize

  def setup
    setup_db

    ["paranoid", "really paranoid", "extremely paranoid"].each do |name|
      ParanoidTime.create! name: name
      ParanoidBoolean.create! name: name
    end

    ParanoidString.create! name: "strings can be paranoid"
    NotParanoid.create! name: "no paranoid goals"
    ParanoidWithCallback.create! name: "paranoid with callbacks"
  end

  def teardown
    teardown_db
  end

  def test_paranoid?
    refute_predicate NotParanoid, :paranoid?
    assert_raise(NoMethodError) { NotParanoid.delete_all! }
    assert_raise(NoMethodError) { NotParanoid.with_deleted }
    assert_raise(NoMethodError) { NotParanoid.only_deleted }

    assert_predicate ParanoidTime, :paranoid?
  end

  def test_scope_inclusion_with_time_column_type
    assert_respond_to ParanoidTime, :deleted_inside_time_window
    assert_respond_to ParanoidTime, :deleted_before_time
    assert_respond_to ParanoidTime, :deleted_after_time

    refute_respond_to ParanoidBoolean, :deleted_inside_time_window
    refute_respond_to ParanoidBoolean, :deleted_before_time
    refute_respond_to ParanoidBoolean, :deleted_after_time
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

  def test_non_persisted_delete
    pt = ParanoidTime.new

    assert_nil pt.paranoid_value
    pt.delete

    assert_not_nil pt.paranoid_value
  end

  def test_non_persisted_destroy!
    pt = ParanoidTime.new

    assert_nil pt.paranoid_value
    pt.destroy!

    assert_not_nil pt.paranoid_value
  end

  def test_halted_destroy
    pt = ParanoidTime.create!(name: "john", destroyable: false)

    assert_raises ActiveRecord::RecordNotDestroyed do
      pt.destroy!
    end
  end

  def test_non_persisted_destroy_fully!
    pt = ParanoidTime.new

    assert_nil pt.paranoid_value
    pt.destroy_fully!

    assert_nil pt.paranoid_value
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

  def test_recovery!
    ParanoidBoolean.first.destroy
    ParanoidBoolean.create(name: "paranoid")

    assert_raise do
      ParanoidBoolean.only_deleted.first.recover!
    end
  end

  def test_recover_has_one_association
    parent = ParanoidBoolean.create(name: "parent")
    child = parent.create_paranoid_has_one_dependant(name: "child")

    parent.destroy

    assert_predicate parent.paranoid_has_one_dependant, :destroyed?

    parent.recover

    refute_predicate parent.paranoid_has_one_dependant, :destroyed?

    child.reload

    refute_predicate child, :destroyed?
  end

  def test_recover_has_many_association
    parent = ParanoidTime.create(name: "parent")
    child = parent.paranoid_has_many_dependants.create(name: "child")

    parent.destroy

    assert_predicate child, :destroyed?

    parent.recover

    assert_equal 1, parent.paranoid_has_many_dependants.count

    child.reload

    refute_predicate child, :destroyed?
  end

  # Rails does not allow saving deleted records
  def test_no_save_after_destroy
    paranoid = ParanoidString.first
    paranoid.destroy
    paranoid.name = "Let's update!"

    assert_not paranoid.save
    assert_raises ActiveRecord::RecordNotSaved do
      paranoid.save!
    end
  end

  def test_scope_chaining
    assert_equal 3, ParanoidBoolean.unscoped.with_deleted.count
    assert_equal 0, ParanoidBoolean.unscoped.only_deleted.count
    assert_equal 0, ParanoidBoolean.with_deleted.only_deleted.count
    assert_equal 3, ParanoidBoolean.with_deleted.with_deleted.count
  end

  def test_only_deleted_with_deleted_with_boolean_paranoid_column
    ParanoidBoolean.first.destroy

    assert_equal 1, ParanoidBoolean.only_deleted.count
    assert_equal 1, ParanoidBoolean.only_deleted.with_deleted.count
  end

  def test_with_deleted_only_deleted_with_boolean_paranoid_column
    ParanoidBoolean.first.destroy

    assert_equal 1, ParanoidBoolean.only_deleted.count
    assert_equal 1, ParanoidBoolean.with_deleted.only_deleted.count
  end

  def test_only_deleted_with_deleted_with_datetime_paranoid_column
    ParanoidTime.first.destroy

    assert_equal 1, ParanoidTime.only_deleted.count
    assert_equal 1, ParanoidTime.only_deleted.with_deleted.count
  end

  def test_with_deleted_only_deleted_with_datetime_paranoid_column
    ParanoidTime.first.destroy

    assert_equal 1, ParanoidTime.only_deleted.count
    assert_equal 1, ParanoidTime.with_deleted.only_deleted.count
  end

  def setup_recursive_tests
    @paranoid_time_object = ParanoidTime.first

    # Create one extra ParanoidHasManyDependant record so that we can validate
    # the correct dependants are recovered.
    ParanoidTime.where("id <> ?", @paranoid_time_object.id).first
      .paranoid_has_many_dependants.create(name: "should not be recovered").destroy

    @paranoid_boolean_count = ParanoidBoolean.count

    assert_equal 0, ParanoidHasManyDependant.count
    assert_equal 0, ParanoidBelongsDependant.count
    assert_equal 1, NotParanoid.count

    (1..3).each do |i|
      has_many_object = @paranoid_time_object.paranoid_has_many_dependants
        .create(name: "has_many_#{i}")
      has_many_object.create_paranoid_belongs_dependant(name: "belongs_to_#{i}")
      has_many_object.save

      paranoid_boolean = @paranoid_time_object.paranoid_booleans
        .create(name: "boolean_#{i}")
      paranoid_boolean.create_paranoid_has_one_dependant(name: "has_one_#{i}")
      paranoid_boolean.save

      @paranoid_time_object.not_paranoids.create(name: "not_paranoid_a#{i}")
    end

    @paranoid_time_object.create_not_paranoid(name: "not_paranoid_belongs_to")
    @paranoid_time_object.create_has_one_not_paranoid(name: "has_one_not_paranoid")

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

    @paranoid_time_object.recover(recursive: true)

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

    # Stop the following from recovering:
    #   - ParanoidHasManyDependant and its ParanoidBelongsDependant
    #   - A single ParanoidBelongsDependant, but not its parent
    Time.stub :now, 2.days.ago do
      @paranoid_time_object.paranoid_has_many_dependants.first.destroy
    end
    Time.stub :now, 1.hour.ago do
      @paranoid_time_object.paranoid_has_many_dependants
        .last.paranoid_belongs_dependant
        .destroy
    end
    @paranoid_time_object.destroy
    @paranoid_time_object.reload

    @paranoid_time_object.recover(recursive: true)

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
    section_1 = ParanoidSection.create(paranoid_thing: child_1)

    child_2 = ParanoidPolygon.create(sides: 3)
    section_2 = ParanoidSection.create(paranoid_thing: child_2)

    assert_equal section_1.paranoid_thing, child_1
    assert_equal section_1.paranoid_thing.class, ParanoidAndroid
    assert_equal section_2.paranoid_thing, child_2
    assert_equal section_2.paranoid_thing.class, ParanoidPolygon

    parent = ParanoidTime.create(name: "paranoid_parent")
    parent.paranoid_sections << section_1
    parent.paranoid_sections << section_2

    assert_equal 4, ParanoidTime.count
    assert_equal 2, ParanoidSection.count
    assert_equal 1, ParanoidAndroid.count
    assert_equal 1, ParanoidPolygon.count

    parent.destroy

    assert_equal 3, ParanoidTime.count
    assert_equal 0, ParanoidSection.count
    assert_equal 0, ParanoidAndroid.count
    assert_equal 0, ParanoidPolygon.count

    parent.reload
    parent.recover

    assert_equal 4, ParanoidTime.count
    assert_equal 2, ParanoidSection.count
    assert_equal 1, ParanoidAndroid.count
    assert_equal 1, ParanoidPolygon.count
  end

  def test_non_recursive_recovery
    setup_recursive_tests

    @paranoid_time_object.destroy
    @paranoid_time_object.reload

    @paranoid_time_object.recover(recursive: false)

    assert_equal 3, ParanoidTime.count
    assert_equal 0, ParanoidHasManyDependant.count
    assert_equal 0, ParanoidBelongsDependant.count
    assert_equal @paranoid_boolean_count, ParanoidBoolean.count
    assert_equal 0, ParanoidHasOneDependant.count
    assert_equal 1, NotParanoid.count
    assert_equal 0, HasOneNotParanoid.count
  end

  def test_dirty
    pt = ParanoidTime.create
    pt.destroy

    assert_not pt.changed?
  end

  def test_delete_dirty
    pt = ParanoidTime.create
    pt.delete

    assert_not pt.changed?
  end

  def test_destroy_fully_dirty
    pt = ParanoidTime.create
    pt.destroy_fully!

    assert_not pt.changed?
  end

  def test_deleted?
    ParanoidTime.first.destroy

    assert_predicate ParanoidTime.with_deleted.first, :deleted?

    ParanoidString.first.destroy

    assert_predicate ParanoidString.with_deleted.first, :deleted?
  end

  def test_delete_deleted?
    ParanoidTime.first.delete

    assert_predicate ParanoidTime.with_deleted.first, :deleted?

    ParanoidString.first.delete

    assert_predicate ParanoidString.with_deleted.first, :deleted?
  end

  def test_destroy_fully_deleted?
    object = ParanoidTime.first
    object.destroy_fully!

    assert_predicate object, :deleted?

    object = ParanoidString.first
    object.destroy_fully!

    assert_predicate object, :deleted?
  end

  def test_deleted_fully?
    ParanoidTime.first.destroy

    assert_not ParanoidTime.with_deleted.first.deleted_fully?

    ParanoidString.first.destroy

    assert_predicate ParanoidString.with_deleted.first, :deleted?
  end

  def test_delete_deleted_fully?
    ParanoidTime.first.delete

    assert_not ParanoidTime.with_deleted.first.deleted_fully?
  end

  def test_destroy_fully_deleted_fully?
    object = ParanoidTime.first
    object.destroy_fully!

    assert_predicate object, :deleted_fully?
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

  def test_recovery_callbacks_without_destroy
    @paranoid_with_callback = ParanoidWithCallback.first
    @paranoid_with_callback.recover

    assert_nil @paranoid_with_callback.called_before_recover
    assert_nil @paranoid_with_callback.called_after_recover
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
    ps = ParanoidString.create!(deleted: "not dead")

    assert_equal 1, ParanoidString.where(id: ps).count
  end

  def test_string_type_with_no_nil_value_after_destroy
    ps = ParanoidString.create!(deleted: "not dead")
    ps.destroy

    assert_equal 0, ParanoidString.where(id: ps).count
  end

  def test_string_type_with_no_nil_value_before_destroy_with_deleted
    ps = ParanoidString.create!(deleted: "not dead")

    assert_equal 1, ParanoidString.with_deleted.where(id: ps).count
  end

  def test_string_type_with_no_nil_value_after_destroy_with_deleted
    ps = ParanoidString.create!(deleted: "not dead")
    ps.destroy

    assert_equal 1, ParanoidString.with_deleted.where(id: ps).count
  end

  def test_string_type_with_no_nil_value_before_destroy_only_deleted
    ps = ParanoidString.create!(deleted: "not dead")

    assert_equal 0, ParanoidString.only_deleted.where(id: ps).count
  end

  def test_string_type_with_no_nil_value_after_destroy_only_deleted
    ps = ParanoidString.create!(deleted: "not dead")
    ps.destroy

    assert_equal 1, ParanoidString.only_deleted.where(id: ps).count
  end

  def test_string_type_with_no_nil_value_after_destroyed_twice
    ps = ParanoidString.create!(deleted: "not dead")
    2.times { ps.destroy }

    assert_equal 0, ParanoidString.with_deleted.where(id: ps).count
  end

  # Test boolean type columns, that are not nullable
  def test_boolean_type_with_no_nil_value_before_destroy
    ps = ParanoidBooleanNotNullable.create!

    assert_equal 1, ParanoidBooleanNotNullable.where(id: ps).count
  end

  def test_boolean_type_with_no_nil_value_after_destroy
    ps = ParanoidBooleanNotNullable.create!
    ps.destroy

    assert_equal 0, ParanoidBooleanNotNullable.where(id: ps).count
  end

  def test_boolean_type_with_no_nil_value_before_destroy_with_deleted
    ps = ParanoidBooleanNotNullable.create!

    assert_equal 1, ParanoidBooleanNotNullable.with_deleted.where(id: ps).count
  end

  def test_boolean_type_with_no_nil_value_after_destroy_with_deleted
    ps = ParanoidBooleanNotNullable.create!
    ps.destroy

    assert_equal 1, ParanoidBooleanNotNullable.with_deleted.where(id: ps).count
  end

  def test_boolean_type_with_no_nil_value_before_destroy_only_deleted
    ps = ParanoidBooleanNotNullable.create!

    assert_equal 0, ParanoidBooleanNotNullable.only_deleted.where(id: ps).count
  end

  def test_boolean_type_with_no_nil_value_after_destroy_only_deleted
    ps = ParanoidBooleanNotNullable.create!
    ps.destroy

    assert_equal 1, ParanoidBooleanNotNullable.only_deleted.where(id: ps).count
  end

  def test_boolean_type_with_no_nil_value_after_destroyed_twice
    ps = ParanoidBooleanNotNullable.create!
    2.times { ps.destroy }

    assert_equal 0, ParanoidBooleanNotNullable.with_deleted.where(id: ps).count
  end

  def test_boolean_type_with_no_nil_value_after_recover
    ps = ParanoidBooleanNotNullable.create!
    ps.destroy

    assert_equal 1, ParanoidBooleanNotNullable.only_deleted.where(id: ps).count

    ps.recover

    assert_equal 1, ParanoidBooleanNotNullable.where(id: ps).count
  end

  def test_boolean_type_with_no_nil_value_after_recover!
    ps = ParanoidBooleanNotNullable.create!
    ps.destroy

    assert_equal 1, ParanoidBooleanNotNullable.only_deleted.where(id: ps).count

    ps.recover!

    assert_equal 1, ParanoidBooleanNotNullable.where(id: ps).count
  end

  def test_no_double_tap_destroys_fully
    ps = ParanoidNoDoubleTapDestroysFully.create!
    2.times { ps.destroy }

    assert_equal 1, ParanoidNoDoubleTapDestroysFully.with_deleted.where(id: ps).count
  end

  def test_decrement_counters_without_touch
    paranoid_boolean = ParanoidBoolean.create!
    paranoid_with_counter_cache = ParanoidWithCounterCache
      .create!(paranoid_boolean: paranoid_boolean)

    assert_equal 1, paranoid_boolean.paranoid_with_counter_caches_count
    updated_at = paranoid_boolean.reload.updated_at

    paranoid_with_counter_cache.destroy

    assert_equal 0, paranoid_boolean.reload.paranoid_with_counter_caches_count
    assert_equal updated_at, paranoid_boolean.reload.updated_at
  end

  def test_decrement_custom_counters
    paranoid_boolean = ParanoidBoolean.create!
    paranoid_with_custom_counter_cache = ParanoidWithCustomCounterCache
      .create!(paranoid_boolean: paranoid_boolean)

    assert_equal 1, paranoid_boolean.custom_counter_cache

    paranoid_with_custom_counter_cache.destroy

    assert_equal 0, paranoid_boolean.reload.custom_counter_cache
  end

  def test_decrement_counters_with_touch
    paranoid_boolean = ParanoidBoolean.create!
    paranoid_with_counter_cache = ParanoidWithTouchAndCounterCache
      .create!(paranoid_boolean: paranoid_boolean)

    assert_equal 1, paranoid_boolean.paranoid_with_touch_and_counter_caches_count
    updated_at = paranoid_boolean.reload.updated_at

    paranoid_with_counter_cache.destroy

    assert_equal 0, paranoid_boolean.reload.paranoid_with_touch_and_counter_caches_count
    assert_not_equal updated_at, paranoid_boolean.reload.updated_at
  end

  def test_touch_belongs_to
    paranoid_boolean = ParanoidBoolean.create!
    paranoid_with_counter_cache = ParanoidWithTouch
      .create!(paranoid_boolean: paranoid_boolean)

    updated_at = paranoid_boolean.reload.updated_at

    paranoid_with_counter_cache.destroy

    assert_not_equal updated_at, paranoid_boolean.reload.updated_at
  end

  def test_destroy_with_optional_belongs_to_and_counter_cache
    ps = ParanoidWithCounterCacheOnOptionalBelognsTo.create!
    ps.destroy

    assert_equal 1, ParanoidWithCounterCacheOnOptionalBelognsTo.only_deleted
      .where(id: ps).count
  end

  def test_hard_destroy_decrement_counters
    paranoid_boolean = ParanoidBoolean.create!
    paranoid_with_counter_cache = ParanoidWithCounterCache
      .create!(paranoid_boolean: paranoid_boolean)

    assert_equal 1, paranoid_boolean.paranoid_with_counter_caches_count

    paranoid_with_counter_cache.destroy_fully!

    assert_equal 0, paranoid_boolean.reload.paranoid_with_counter_caches_count
  end

  def test_hard_destroy_decrement_custom_counters
    paranoid_boolean = ParanoidBoolean.create!
    paranoid_with_custom_counter_cache = ParanoidWithCustomCounterCache
      .create!(paranoid_boolean: paranoid_boolean)

    assert_equal 1, paranoid_boolean.custom_counter_cache

    paranoid_with_custom_counter_cache.destroy_fully!

    assert_equal 0, paranoid_boolean.reload.custom_counter_cache
  end

  def test_increment_counters
    paranoid_boolean = ParanoidBoolean.create!
    paranoid_with_counter_cache = ParanoidWithCounterCache
      .create!(paranoid_boolean: paranoid_boolean)

    assert_equal 1, paranoid_boolean.paranoid_with_counter_caches_count

    paranoid_with_counter_cache.destroy

    assert_equal 0, paranoid_boolean.reload.paranoid_with_counter_caches_count

    paranoid_with_counter_cache.recover

    assert_equal 1, paranoid_boolean.reload.paranoid_with_counter_caches_count
  end

  def test_increment_custom_counters
    paranoid_boolean = ParanoidBoolean.create!
    paranoid_with_custom_counter_cache = ParanoidWithCustomCounterCache
      .create!(paranoid_boolean: paranoid_boolean)

    assert_equal 1, paranoid_boolean.custom_counter_cache

    paranoid_with_custom_counter_cache.destroy

    assert_equal 0, paranoid_boolean.reload.custom_counter_cache

    paranoid_with_custom_counter_cache.recover

    assert_equal 1, paranoid_boolean.reload.custom_counter_cache
  end

  def test_explicitly_setting_table_name_after_acts_as_paranoid_macro
    assert_equal "explicit_table.deleted_at", ParanoidWithExplicitTableNameAfterMacro
      .paranoid_column_reference
  end

  def test_deleted_after_time
    ParanoidTime.first.destroy

    assert_equal 0, ParanoidTime.deleted_after_time(1.hour.from_now).count
    assert_equal 1, ParanoidTime.deleted_after_time(1.hour.ago).count
  end

  def test_deleted_before_time
    ParanoidTime.first.destroy

    assert_equal 1, ParanoidTime.deleted_before_time(1.hour.from_now).count
    assert_equal 0, ParanoidTime.deleted_before_time(1.hour.ago).count
  end

  def test_deleted_inside_time_window
    ParanoidTime.first.destroy

    assert_equal 1, ParanoidTime.deleted_inside_time_window(1.minute.ago, 2.minutes).count
    assert_equal 1,
                 ParanoidTime.deleted_inside_time_window(1.minute.from_now, 2.minutes).count
    assert_equal 0, ParanoidTime.deleted_inside_time_window(3.minutes.ago, 1.minute).count
    assert_equal 0,
                 ParanoidTime.deleted_inside_time_window(3.minutes.from_now, 1.minute).count
  end
end
