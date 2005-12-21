require File.join(File.dirname(__FILE__), 'test_helper')

class Widget < ActiveRecord::Base
  acts_as_paranoid
  has_many :categories, :dependent => true
  has_and_belongs_to_many :habtm_categories, :class_name => 'Category'
  has_one :category
  belongs_to :parent_category, :class_name => 'Category'
end

class Category < ActiveRecord::Base
  belongs_to :widget
  acts_as_paranoid
end

class NonParanoidAndroid < ActiveRecord::Base
end

class ParanoidTest < Test::Unit::TestCase
  fixtures :widgets, :categories, :categories_widgets

  def test_should_set_deleted_at
    assert_equal 1, Widget.count
    assert_equal 1, Category.count
    widgets(:widget_1).destroy
    assert_equal 0, Widget.count
    assert_equal 0, Category.count
    assert_equal 2, Widget.count_with_deleted
    assert_equal 4, Category.count_with_deleted
  end
  
  def test_should_destroy
    assert_equal 1, Widget.count
    assert_equal 1, Category.count
    widgets(:widget_1).destroy!
    assert_equal 0, Widget.count
    assert_equal 0, Category.count
    assert_equal 1, Widget.count_with_deleted
    # Category doesn't get destroyed because the dependent before_destroy callback uses #destroy
    assert_equal 4, Category.count_with_deleted
  end
  
  def test_should_not_count_deleted
    assert_equal 1, Widget.count
    assert_equal 1, Widget.count(['title=?', 'widget 1'])
    assert_equal 2, Widget.count_with_deleted
  end
  
  def test_should_not_find_deleted
    assert_equal [widgets(:widget_1)], Widget.find(:all)
    assert_equal [1, 2], Widget.find_with_deleted(:all, :order => 'id').collect { |w| w.id }
  end
  
  def test_should_not_find_deleted_associations
    assert_equal 2, Category.count_with_deleted('widget_id=1')
    
    assert_equal 1, widgets(:widget_1).categories.size
    assert_equal [categories(:category_1)], widgets(:widget_1).categories
    
    assert_equal 1, widgets(:widget_1).habtm_categories.size
    assert_equal [categories(:category_1)], widgets(:widget_1).habtm_categories
  end
  
  def test_should_find_first_with_deleted
    assert_equal widgets(:widget_1), Widget.find(:first)
    assert_equal 2, Widget.find_with_deleted(:first, :order => 'id desc').id
  end
  
  def test_should_find_single_id
    assert Widget.find(1)
    assert Widget.find_with_deleted(2)
    assert_raises(ActiveRecord::RecordNotFound) { Widget.find(2) }
  end
  
  def test_should_find_multiple_ids
    assert_equal [1,2], Widget.find_with_deleted(1,2).sort_by { |w| w.id }.collect { |w| w.id }
    assert_equal [1,2], Widget.find_with_deleted([1,2]).sort_by { |w| w.id }.collect { |w| w.id }
    assert_raises(ActiveRecord::RecordNotFound) { Widget.find(1,2) }
  end
  
  def test_should_ignore_multiple_includes
    Widget.class_eval { acts_as_paranoid }
    assert Widget.find(1)
  end

  def test_should_not_override_scopes_when_counting
    assert_equal 1, Widget.with_scope(:find => { :conditions => "title = 'widget 1'" }) { Widget.count }
    assert_equal 0, Widget.with_scope(:find => { :conditions => "title = 'deleted widget 2'" }) { Widget.count }
    assert_equal 1, Widget.with_scope(:find => { :conditions => "title = 'deleted widget 2'" }) { Widget.count_with_deleted }
  end

  def test_should_not_override_scopes_when_finding
    assert_equal [1], Widget.with_scope(:find => { :conditions => "title = 'widget 1'" }) { Widget.find(:all) }.ids
    assert_equal [],  Widget.with_scope(:find => { :conditions => "title = 'deleted widget 2'" }) { Widget.find(:all) }.ids
    assert_equal [2], Widget.with_scope(:find => { :conditions => "title = 'deleted widget 2'" }) { Widget.find_with_deleted(:all) }.ids
  end

  def test_should_allow_multiple_scoped_calls_when_finding
    Widget.with_scope(:find => { :conditions => "title = 'deleted widget 2'" }) do
      assert_equal [2], Widget.find_with_deleted(:all).ids
      assert_equal [2], Widget.find_with_deleted(:all).ids, "clobbers the constrain on the unmodified find"
      assert_equal [], Widget.find(:all).ids
      assert_equal [], Widget.find(:all).ids, 'clobbers the constrain on a paranoid find'
    end
  end

  def test_should_allow_multiple_scoped_calls_when_counting
    Widget.with_scope(:find => { :conditions => "title = 'deleted widget 2'" }) do
      assert_equal 1, Widget.count_with_deleted
      assert_equal 1, Widget.count_with_deleted, "clobbers the constrain on the unmodified find"
      assert_equal 0, Widget.count
      assert_equal 0, Widget.count, 'clobbers the constrain on a paranoid find'
    end
  end

  def test_should_give_paranoid_status
    assert Widget.paranoid?
    assert !NonParanoidAndroid.paranoid?
  end

  # sorry charlie, these are out!
  #def test_should_find_deleted_has_many_assocations_on_deleted_records_by_default
  #  w = Widget.find_with_deleted 2
  #  assert_equal 2, w.categories.length
  #  assert_equal 2, w.categories(true).size
  #end
  #
  #def test_should_find_deleted_habtm_assocations_on_deleted_records_by_default
  #  w = Widget.find_with_deleted 2
  #  assert_equal 2, w.habtm_categories.length
  #  assert_equal 2, w.habtm_categories(true).size
  #end
  #
  #def test_should_find_deleted_has_one_associations_on_deleted_records_by_default
  #  c = Category.find_with_deleted 3
  #  w = Widget.find_with_deleted 2
  #  assert_equal c, w.category
  #end
  #
  #def test_should_find_deleted_belongs_to_associations_on_deleted_records_by_default
  #  c = Category.find_with_deleted 3
  #  w = Widget.find_with_deleted 2
  #  assert_equal c, w.parent_category
  #end
end

class Array
  def ids
    collect { |i| i.id }
  end
end