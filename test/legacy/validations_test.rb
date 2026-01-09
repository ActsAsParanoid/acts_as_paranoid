# frozen_string_literal: true

require "test_helper"

class ValidatesUniquenessTest < ActiveSupport::TestCase
  class ParanoidUniqueness < ActiveRecord::Base
    acts_as_paranoid

    validates_uniqueness_of :name
  end

  class ParanoidUniquenessWithoutDeleted < ActiveRecord::Base
    acts_as_paranoid
    validates_as_paranoid

    validates_uniqueness_of_without_deleted :name
  end

  class ParanoidWithSerializedColumn < ActiveRecord::Base
    acts_as_paranoid
    validates_as_paranoid

    serialize :colors

    validates_uniqueness_of_without_deleted :colors
  end

  class ParanoidWithScopedValidation < ActiveRecord::Base
    acts_as_paranoid
    validates_uniqueness_of :name, scope: :category
  end

  def setup
    ActiveRecord::Schema.define(version: 1) do
      create_table :paranoid_uniquenesses do |t|
        t.string    :name
        t.datetime  :deleted_at

        timestamps t
      end

      create_table :paranoid_uniqueness_without_deleteds do |t|
        t.string    :name
        t.datetime  :deleted_at

        timestamps t
      end

      create_table :paranoid_with_serialized_columns do |t|
        t.string :name
        t.datetime :deleted_at
        t.string :colors

        timestamps t
      end

      create_table :paranoid_with_scoped_validations do |t|
        t.string :name
        t.string :category
        t.datetime :deleted_at
        timestamps t
      end
    end
  end

  def teardown
    teardown_db
  end

  def test_should_include_deleted_by_default
    ParanoidUniqueness.create!(name: "paranoid")
    ParanoidUniqueness.new(name: "paranoid").tap do |record|
      refute_predicate record, :valid?
      ParanoidUniqueness.first.destroy

      refute_predicate record, :valid?
      ParanoidUniqueness.only_deleted.first.destroy!

      assert_predicate record, :valid?
    end
  end

  def test_should_validate_without_deleted
    ParanoidUniquenessWithoutDeleted.create!(name: "paranoid")
    ParanoidUniquenessWithoutDeleted.new(name: "paranoid").tap do |record|
      refute_predicate record, :valid?
      ParanoidUniquenessWithoutDeleted.first.destroy

      assert_predicate record, :valid?
      ParanoidUniquenessWithoutDeleted.only_deleted.first.destroy!

      assert_predicate record, :valid?
    end
  end

  def test_validate_serialized_attribute_without_deleted
    ParanoidWithSerializedColumn.create!(name: "ParanoidWithSerializedColumn #1",
                                         colors: %w[Cyan Maroon])
    record = ParanoidWithSerializedColumn.new(name: "ParanoidWithSerializedColumn #2")
    record.colors = %w[Cyan Maroon]

    refute_predicate record, :valid?

    record.colors = %w[Beige Turquoise]

    assert_predicate record, :valid?
  end

  def test_updated_serialized_attribute_validated_without_deleted
    record = ParanoidWithSerializedColumn.create!(name: "ParanoidWithSerializedColumn #1",
                                                  colors: %w[Cyan Maroon])
    record.update!(colors: %w[Beige Turquoise])

    assert_predicate record, :valid?
  end

  def test_models_with_scoped_validations_can_be_multiply_deleted
    model_a = ParanoidWithScopedValidation.create(name: "Model A", category: "Category A")
    model_b = ParanoidWithScopedValidation.create(name: "Model B", category: "Category B")

    ParanoidWithScopedValidation.delete([model_a.id, model_b.id])

    assert_paranoid_deletion(model_a)
    assert_paranoid_deletion(model_b)
  end

  def test_models_with_scoped_validations_can_be_multiply_destroyed
    model_a = ParanoidWithScopedValidation.create(name: "Model A", category: "Category A")
    model_b = ParanoidWithScopedValidation.create(name: "Model B", category: "Category B")

    ParanoidWithScopedValidation.destroy([model_a.id, model_b.id])

    assert_paranoid_deletion(model_a)
    assert_paranoid_deletion(model_b)
  end
end
