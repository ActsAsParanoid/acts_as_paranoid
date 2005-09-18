require 'abstract_unit'

class Widget < ActiveRecord::Base
  has_many :categories, :dependent => true
  has_and_belongs_to_many :habtm_categories, :class_name => 'Category'
  acts_as_paranoid
end

class Category < ActiveRecord::Base
  belongs_to :widget
  acts_as_paranoid
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
    assert_equal 2, Category.count_with_deleted
  end
  
  def test_should_destroy
    assert_equal 1, Widget.count
    assert_equal 1, Category.count
    widgets(:widget_1).destroy!
    assert_equal 0, Widget.count
    assert_equal 0, Category.count
    assert_equal 1, Widget.count_with_deleted
    # Category doesn't get destroyed because the dependent before_destroy callback uses #destroy
    assert_equal 2, Category.count_with_deleted
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
end