# frozen_string_literal: true

require "test_helper"

class ValidatesUniquenessTest < ParanoidBaseTest
  def test_should_include_deleted_by_default
    ParanoidTime.new(name: "paranoid").tap do |record|
      refute record.valid?
      ParanoidTime.first.destroy
      refute record.valid?
      ParanoidTime.only_deleted.first.destroy!
      assert_predicate record, :valid?
    end
  end

  def test_should_validate_without_deleted
    ParanoidBoolean.new(name: "paranoid").tap do |record|
      refute record.valid?
      ParanoidBoolean.first.destroy
      assert_predicate record, :valid?
      ParanoidBoolean.only_deleted.first.destroy!
      assert_predicate record, :valid?
    end
  end

  def test_validate_serialized_attribute_without_deleted
    ParanoidWithSerializedColumn.create!(name: "ParanoidWithSerializedColumn #1",
                                         colors: %w[Cyan Maroon])
    record = ParanoidWithSerializedColumn.new(name: "ParanoidWithSerializedColumn #2")
    record.colors = %w[Cyan Maroon]
    refute record.valid?

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
