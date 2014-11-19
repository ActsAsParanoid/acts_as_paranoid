require 'test_helper'

class MultipleDefaultScopesTest < ParanoidBaseTest
  def setup
    setup_db

    # Naturally, the default scope for humans is male. Sexism++
    ParanoidHuman.create! :gender => 'male'
    ParanoidHuman.create! :gender => 'male'
    ParanoidHuman.create! :gender => 'male'
    ParanoidHuman.create! :gender => 'female'

    assert_equal 3, ParanoidHuman.count
    assert_equal 4, ParanoidHuman.unscoped.count
  end

  def test_fake_removal_with_multiple_default_scope
    ParanoidHuman.first.destroy
    assert_equal 2, ParanoidHuman.count
    assert_equal 3, ParanoidHuman.with_deleted.count
    assert_equal 1, ParanoidHuman.only_deleted.count
    assert_equal 4, ParanoidHuman.unscoped.count

    ParanoidHuman.destroy_all
    assert_equal 0, ParanoidHuman.count
    assert_equal 3, ParanoidHuman.with_deleted.count
    assert_equal 3, ParanoidHuman.with_deleted.count
    assert_equal 4, ParanoidHuman.unscoped.count
  end

  def test_real_removal_with_multiple_default_scope
    # two-step
    ParanoidHuman.first.destroy
    ParanoidHuman.only_deleted.first.destroy
    assert_equal 2, ParanoidHuman.count
    assert_equal 2, ParanoidHuman.with_deleted.count
    assert_equal 0, ParanoidHuman.only_deleted.count
    assert_equal 3, ParanoidHuman.unscoped.count

    ParanoidHuman.first.destroy_fully!
    assert_equal 1, ParanoidHuman.count
    assert_equal 1, ParanoidHuman.with_deleted.count
    assert_equal 0, ParanoidHuman.only_deleted.count
    assert_equal 2, ParanoidHuman.unscoped.count

    ParanoidHuman.delete_all!
    assert_equal 0, ParanoidHuman.count
    assert_equal 0, ParanoidHuman.with_deleted.count
    assert_equal 0, ParanoidHuman.only_deleted.count
    assert_equal 1, ParanoidHuman.unscoped.count
  end
end
