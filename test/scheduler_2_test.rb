
#
# Testing Rufus
#
# John Mettraux at openwfe.org
#
# Sun Oct 29 16:18:25 JST 2006
#

require 'test/unit'
require 'openwfe/util/scheduler'

#
# testing otime and the scheduler
#

class Scheduler2Test < Test::Unit::TestCase

  #def setup
  #end

  #def teardown
  #end

  def test_0

    scheduler = Rufus::Scheduler.new
    scheduler.start

    counter = 0
    $error_counter = 0

    def scheduler.lwarn (&block)
      #puts block.call
      $error_counter += 1
    end

    job_id = scheduler.schedule_every "500" do
      counter += 1
      raise "exception!"
    end

    sleep 2.300

    scheduler.sstop

    assert_equal 4, counter, "execution count wrong"
    assert_equal 4, $error_counter, "error count wrong"
  end

  def test_1

    # repeating myself

    scheduler = Rufus::Scheduler.new
    scheduler.start

    counter = 0
    $error_counter = 0

    def scheduler.lwarn (&block)
      #puts block.call
      $error_counter += 1
    end

    job_id = scheduler.schedule_every "500", :try_again => false do
      counter += 1
      raise "exception?"
    end

    sleep 2.300

    scheduler.sstop

    assert_equal 1, counter, "execution count wrong"
    assert_equal 1, $error_counter, "error count wrong"
  end

  def test_2

    scheduler = Rufus::Scheduler.new
    scheduler.start

    def scheduler.lwarn (&block)
      puts block.call
    end

    counter = 0

    job_id = scheduler.schedule_every "500" do |job_id, at, params|
      counter += 1
      params[:dont_reschedule] = true if counter == 2
    end

    sleep 3.000

    assert_equal 2, counter
  end

  def test_3

    # repeating myself ...

    scheduler = Rufus::Scheduler.new
    scheduler.start

    def scheduler.lwarn (&block)
      puts block.call
    end

    counter = 0

    job_id = scheduler.schedule_every "500" do |job_id, at, params|
      counter += 1
      params[:every] = "1s" if counter == 2
    end

    sleep 5.000

    assert_equal 2 + 3, counter
  end

end
