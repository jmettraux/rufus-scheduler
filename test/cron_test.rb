
#
# Testing the rufus-scheduler
#
# John Mettraux at openwfe.org
#
# Sun Oct 29 16:18:25 JST 2006
#

require File.dirname(__FILE__) + '/test_base'


#
# testing otime and the scheduler (its cron aspect)
#
class CronTest < Test::Unit::TestCase

  #def setup
  #end

  #def teardown
  #end

  def test_0

    $var = 0

    scheduler = Rufus::Scheduler.new
    scheduler.start

    sid = scheduler.schedule(
      '* * * * *',
      :schedulable => CounterSchedulable.new)

    assert sid, "scheduler did not return a job id"

    sleep 120
    scheduler.stop

    #puts ">#{$var}<"

    assert_equal 2, $var
  end

  def test_1

    scheduler = Rufus::Scheduler.new
    scheduler.start

    sec = nil
    has_gone_wrong = false
    counter = 0

    scheduler.schedule "* * * * * *" do
      t = Time.new
      if (t.sec == sec)
        has_gone_wrong = true
      #  print "x"
      #else
      #  print "."
      end
      #STDOUT.flush
      sec = t.sec
      counter = counter + 1
    end

    sleep 10
    scheduler.stop

    #assert_equal 10, counter
    assert [ 9, 10 ].include?(counter), "not 9 or 10 but #{counter}"
    assert (not has_gone_wrong)
  end

  def test_2

    scheduler = Rufus::Scheduler.new
    scheduler.start

    counter = 0

    scheduler.schedule "7 * * * * *" do
      counter += 1
    end

    sleep 61
    scheduler.stop

    assert_equal 1, counter
      # baby just one ... time
  end

  #
  # testing cron unschedule
  #
  def test_3

    scheduler = Rufus::Scheduler.new
    scheduler.start

    counter = 0

    job_id = scheduler.schedule "* * * * *" do
      counter += 1
    end

    sleep 0.300

    #puts "job_id : #{job_id}"

    assert_equal 1, scheduler.cron_job_count
    assert_equal 0, scheduler.find_schedulables("nada").size

    scheduler.unschedule job_id

    sleep 0.300

    assert_equal 0, scheduler.cron_job_count

    scheduler.stop
  end

  def test_4

    scheduler = Rufus::Scheduler.start_new

    val = nil

    job_id = scheduler.schedule "* * * * * *" do |job_id, cron_line, params|
      val = params.inspect
    end

    sleep 2

    assert_equal '{}', val

    scheduler.stop
  end

  protected

    class CounterSchedulable
      include Rufus::Schedulable

      def trigger (params)
        $var = $var + 1
      end
    end

end
