
#
# Testing the 'rufus-scheduler'
#
# John Mettraux at openwfe.org
#
# Sat Jan 26 20:05:57 JST 2008
#

$:.unshift(File.dirname(__FILE__) + '/../lib')

require 'test/unit'
require 'rufus/scheduler'


class Scheduler5Test < Test::Unit::TestCase

  #
  # Testing the :first_at parameter
  #
  def test_0

    s = Rufus::Scheduler.new
    s.start

    $count = 0

    fa = Time.now + 3

    s.schedule_every '1s', :first_at => fa do
      $count += 1
    end

    sleep 1

    assert_equal 0, $count

    sleep 3

    assert_equal 1, $count

    sleep 1

    assert_equal 2, $count

    s.stop
  end

  #
  # Testing the :first_in parameter
  #
  def test_1

    s = Rufus::Scheduler.new
    s.start

    $count = 0

    s.schedule_every '1s', :first_in => '3s' do
      $count += 1
    end

    sleep 1

    assert_equal 0, $count

    sleep 3

    assert_equal 1, $count

    sleep 1

    assert_equal 2, $count

    s.stop
  end

  #
  # Testing the :timeout parameter
  #
  def test_2

    s = Rufus::Scheduler.start_new

    $count = 0
    $error = nil

    def s.log_exception (e)
      $error = e
    end

    s.in '3s', :timeout => '2s' do
      loop do
        $count += 1
        sleep 3
      end
    end

    sleep 6

    assert_kind_of Rufus::TimeOutError, $error
    assert_equal 1, $count

    s.stop
  end

  #
  # Testing the :first_in + :timeout parameters
  #
  def test_3

    s = Rufus::Scheduler.start_new

    $count = 0
    $error = nil
    $jobs = nil

    def s.log_exception (e)
      $error = e
    end

    s.every '10s', :first_in => '3s', :timeout => '2s' do
      Thread.pass # let the timeout job get scheduled
      $jobs = s.all_jobs.collect { |j| j.tags }.flatten
      $count += 1
      sleep 5
    end

    sleep 6

    assert_kind_of Rufus::TimeOutError, $error
    assert_equal 1, $count
    assert_equal [ 'timeout' ], $jobs

    assert_equal [], s.all_jobs

    s.stop
  end
end

