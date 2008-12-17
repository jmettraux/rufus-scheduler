
#
# Testing the 'rufus-scheduler'
#
# John Mettraux at openwfe.org
#
# Sun Jul 13 19:20:27 JST 2008
#

$:.unshift(File.dirname(__FILE__) + '/../lib')

require 'test/unit'
require 'rufus/scheduler'


#
# checking if bug #20893 got fixed
#
class Scheduler7Test < Test::Unit::TestCase

  def test_0

    count = 0

    s = Rufus::Scheduler.start_new

    job_id = s.schedule_every('5s') do |job_id, at, params|
      count += 1
      sleep 3
    end

    sleep 6

    assert_equal 1, s.every_job_count

    s.unschedule job_id

    sleep 6

    s.stop

    assert_equal 0, s.every_job_count
    assert_equal 1, count
  end
end

