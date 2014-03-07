require 'test_helper'

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

  def test_models_with_scoped_validations_can_be_multiply_deleted
    model_a = ParanoidWithScopedValidation.create(:name => "Model A", :category => "Category A")
    model_b = ParanoidWithScopedValidation.create(:name => "Model B", :category => "Category B")

    ParanoidWithScopedValidation.delete([model_a.id, model_b.id])

    assert_paranoid_deletion(model_a)
    assert_paranoid_deletion(model_b)
  end

  def test_models_with_scoped_validations_can_be_multiply_destroyed
    model_a = ParanoidWithScopedValidation.create(:name => "Model A", :category => "Category A")
    model_b = ParanoidWithScopedValidation.create(:name => "Model B", :category => "Category B")

    ParanoidWithScopedValidation.destroy([model_a.id, model_b.id])

    assert_paranoid_deletion(model_a)
    assert_paranoid_deletion(model_b)
  end
end
