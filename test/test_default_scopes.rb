# frozen_string_literal: true

require "test_helper"

class MultipleDefaultScopesTest < ParanoidBaseTest
  def setup
    setup_db

    ParanoidPolygon.create! sides: 3
    ParanoidPolygon.create! sides: 3
    ParanoidPolygon.create! sides: 3
    ParanoidPolygon.create! sides: 8

    assert_equal 3, ParanoidPolygon.count
    assert_equal 4, ParanoidPolygon.unscoped.count
  end

  def test_fake_removal_with_multiple_default_scope
    ParanoidPolygon.first.destroy
    assert_equal 2, ParanoidPolygon.count
    assert_equal 3, ParanoidPolygon.with_deleted.count
    assert_equal 1, ParanoidPolygon.only_deleted.count
    assert_equal 4, ParanoidPolygon.unscoped.count

    ParanoidPolygon.destroy_all
    assert_equal 0, ParanoidPolygon.count
    assert_equal 3, ParanoidPolygon.with_deleted.count
    assert_equal 3, ParanoidPolygon.with_deleted.count
    assert_equal 4, ParanoidPolygon.unscoped.count
  end

  def test_real_removal_with_multiple_default_scope
    # two-step
    ParanoidPolygon.first.destroy
    ParanoidPolygon.only_deleted.first.destroy
    assert_equal 2, ParanoidPolygon.count
    assert_equal 2, ParanoidPolygon.with_deleted.count
    assert_equal 0, ParanoidPolygon.only_deleted.count
    assert_equal 3, ParanoidPolygon.unscoped.count

    ParanoidPolygon.first.destroy_fully!
    assert_equal 1, ParanoidPolygon.count
    assert_equal 1, ParanoidPolygon.with_deleted.count
    assert_equal 0, ParanoidPolygon.only_deleted.count
    assert_equal 2, ParanoidPolygon.unscoped.count

    ParanoidPolygon.delete_all!
    assert_equal 0, ParanoidPolygon.count
    assert_equal 0, ParanoidPolygon.with_deleted.count
    assert_equal 0, ParanoidPolygon.only_deleted.count
    assert_equal 1, ParanoidPolygon.unscoped.count
  end
end
