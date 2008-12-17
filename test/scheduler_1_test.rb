
#
# Testing Rufus
#
# John Mettraux at openwfe.org
#
# Sun Oct 29 16:18:25 JST 2006
#

$:.unshift(File.dirname(__FILE__) + '/../lib')

require 'test/unit'
require 'openwfe/util/scheduler'


#
# testing otime and the scheduler
#
class Scheduler1Test < Test::Unit::TestCase

  def test_0

    scheduler = Rufus::Scheduler.new
    scheduler.start

    job_id = scheduler.schedule_every "500", :tags => "Avery" do
      # don't do a thing
    end

    sleep 0.300

    count = nil

    200_000.times do |i|
      break if scheduler.get_job(job_id) == nil
      count = i + 1
    end

    scheduler.sstop

    assert_equal 200_000, count
  end

  def test_1

    scheduler = Rufus::Scheduler.start_new

    job_id = scheduler.schedule_every "500", :tags => "Avery" do
      # don't do a thing
    end

    sleep 0.300

    count = 1

    200_000.times do
      count = scheduler.find_jobs("Avery").size
      #p scheduler.instance_variable_get(:@non_cron_jobs).keys if count != 1
      break if count != 1
    end

    scheduler.sstop

    assert_equal 1, count
  end

  #
  # testing "deviation", if I may call it like that...
  #
  def _test_2

    scheduler = Rufus::Scheduler.start_new
    last = nil
    job_id = scheduler.schedule_every "1s" do
      t = Time.now
      puts t.to_f
    end
    sleep 4 * 60
    scheduler.sstop
  end

end
