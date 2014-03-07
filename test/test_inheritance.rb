require 'test_helper'

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
