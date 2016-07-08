require 'test_helper'

class PreloaderAssociationTest < ParanoidBaseTest
  def test_includes_with_deleted
    paranoid_time = ParanoidTime.first
    paranoid_has_many_dependant = paranoid_time.paranoid_has_many_dependants.create(:name => 'dependant!')

    paranoid_time.destroy

    ParanoidHasManyDependant.with_deleted.includes(:paranoid_time_with_deleted).each do |hasmany|
      assert_not_nil hasmany.paranoid_time_with_deleted
    end
  end

  def test_includes_with_deleted_with_polymorphic_parent
    not_paranoid_parent = NotParanoidHasManyAsParent.create(name: 'not paranoid parent')
    paranoid_parent = ParanoidHasManyAsParent.create(name: 'paranoid parent')
    ParanoidBelongsToPolymorphic.create(:name => 'belongs_to', :parent => not_paranoid_parent)
    ParanoidBelongsToPolymorphic.create(:name => 'belongs_to', :parent => paranoid_parent)

    paranoid_parent.destroy

    ParanoidBelongsToPolymorphic.with_deleted.includes(:parent).each do |hasmany|
      assert_not_nil hasmany.parent
    end
  end
end
