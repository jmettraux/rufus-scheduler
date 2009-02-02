
#
# Testing the rufus-scheduler
#
# John Mettraux at openwfe.org
#
# Sun Oct 29 16:18:25 JST 2006
#

require File.dirname(__FILE__) + '/test_base'


class Scheduler3Test < Test::Unit::TestCase

  #
  # Testing tags
  #
  def test_0

    scheduler = Rufus::Scheduler.new
    scheduler.start

    value = nil

    scheduler.schedule_in "3s", :tags => "fish" do
      value = "fish"
    end

    sleep 0.300 # let the job get really scheduled

    assert_equal [], scheduler.find_jobs('deer')
    assert_equal 1, scheduler.find_jobs('fish').size

    scheduler.schedule "* * * * *", :tags => "fish" do
      value = "cron-fish"
    end
    scheduler.cron "* * * * *", :tags => "vegetable" do
      value = "daikon"
    end

    sleep 0.300 # let the jobs get really scheduled

    assert_equal 2, scheduler.find_jobs('fish').size
    #puts scheduler.find_jobs('fish')

    assert_equal(
      3,
      scheduler.all_jobs.size)
    assert_equal(
      [ "Rufus::CronJob", "Rufus::CronJob", "Rufus::AtJob" ],
      scheduler.all_jobs.collect { |j| j.class.name })

    scheduler.find_jobs('fish').each do |job|
      scheduler.unschedule(job.job_id)
    end

    sleep 0.300 # give it some time to unschedule

    assert_equal [], scheduler.find_jobs('fish')
    assert_equal 1, scheduler.find_jobs('vegetable').size

    scheduler.find_jobs('vegetable')[0].unschedule

    sleep 0.300 # give it some time to unschedule

    assert_equal 0, scheduler.find_jobs('vegetable').size
  end

end
