
#
# Testing the 'rufus-scheduler'
#
# John Mettraux at openwfe.org
#
# Tue Jan  8 13:46:17 JST 2008
#

$:.unshift(File.dirname(__FILE__) + '/../lib')

require 'test/unit'
require 'rufus/scheduler'


class Scheduler4Test < Test::Unit::TestCase

  #
  # Checking that a sleep in a schedule won't raise any exception
  #
  def test_0

    s = Rufus::Scheduler.new
    s.start

    $exception = nil

    class << s
      def lwarn (&block)
        $exception = block.call
      end
    end

    counters = Counters.new

    s.schedule_every '2s' do
      counters.inc :a
      sleep 4
      counters.inc :b
    end
    s.schedule_every '3s' do
      counters.inc :c
    end
    #p Time.now.to_f

    #sleep 10.600
    sleep 11.900

    s.stop

    assert_nil($exception)
    assert_equal({ :a => 3, :b => 2, :c => 3 }, counters.counters)
  end

  protected

    class Counters

      attr_reader :counters

      def initialize

        @counters = {}
      end

      def inc (counter)

        @counters[counter] ||= 0
        @counters[counter] += 1

        #puts(
        #  "#{counter} _ " +
        #  "#{Time.now.to_f}  #{@counters.inspect} " +
        #  "(#{Thread.current.object_id})")
      end
    end

end
