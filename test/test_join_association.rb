require 'test_helper'

class JoinAssociationTest < ParanoidBaseTest
  
  def test_joins_has_many_association_should_exclude_deleted_record
    paranoid_one = ParanoidTime.create! :name => 'bla bla one!'
    paranoid_one_many = paranoid_one.paranoid_has_many_dependants.create! :name => 'bla bla one many!'
    paranoid_one_with_deleted = ParanoidTime.create! :name => 'bla bla another!'
    paranoid_one_many_deleted = paranoid_one_with_deleted.paranoid_has_many_dependants.create! :name => 'bla bla one many!', :deleted_at => Time.now
    
    assert ParanoidTime.joins(:paranoid_has_many_dependants) == [paranoid_one], "has_many should only contain the #{paranoid_one.inspect} record"
  end

  def test_joins_belongs_to_association_should_exclude_deleted_record
    paranoid_one = ParanoidTime.create! :name => 'bla bla one!'
    paranoid_one_many = paranoid_one.paranoid_has_many_dependants.create! :name => 'bla bla one many!'
    paranoid_one_with_deleted = ParanoidTime.create! :name => 'bla bla another!', :deleted_at => Time.now
    paranoid_one_many_deleted = paranoid_one_with_deleted.paranoid_has_many_dependants.create! :name=> 'bla bla one many with deleted!'
    
    assert ParanoidHasManyDependant.joins(:paranoid_time) == [paranoid_one_many], "belongs_to should only contain the #{paranoid_one_many.inspect} record"
  end
  
end
