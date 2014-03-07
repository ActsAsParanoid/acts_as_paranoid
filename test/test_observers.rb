require 'test_helper'

class ParanoidObserverTest < ParanoidBaseTest
  def test_called_observer_methods
    @subject = ParanoidWithCallback.new
    @subject.save

    assert_nil ParanoidObserver.instance.called_before_recover
    assert_nil ParanoidObserver.instance.called_after_recover

    ParanoidWithCallback.find(@subject.id).recover

    assert_equal @subject, ParanoidObserver.instance.called_before_recover
    assert_equal @subject, ParanoidObserver.instance.called_after_recover
  end
end
