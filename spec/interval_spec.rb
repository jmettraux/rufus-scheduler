
#
# Specifying rufus-scheduler
#
# Wed Aug  7 06:20:55 JST 2013
#

require 'spec_helper'


describe Rufus::Scheduler do

  before :each do
    @scheduler = Rufus::Scheduler.new
  end
  after :each do
    @scheduler.shutdown
  end

  describe '#interval' do

    it 'adds a job' do

      @scheduler.interval(10) do
      end

      @scheduler.jobs.size.should == 1
      @scheduler.jobs.first.class.should == Rufus::Scheduler::IntervalJob
    end

    it 'triggers a job (2 times)' do

      counter = 0

      @scheduler.interval(0.4) do
        counter += 1
      end

      sleep 2.0

      counter.should > 2
    end

    it 'triggers, but reschedules after the trigger execution' do

      pending

      chronos = []

      @scheduler.interval(0.4) do
        now = Time.now
        last, delta = chronos.last
        chronos << [ now, last ? now - last : nil ]
        sleep 0.5
      end

      sleep 0.1 while chronos.size < 4

      deltas = chronos.collect(&:last).compact

      pp chronos
      pp deltas

      deltas.each do |d|
        d.should >= 0.9
      end
    end

#    it 'does not remove the job after execution' do
#
#      @scheduler.every(0.4) do
#      end
#
#      sleep 0.9
#
#      @scheduler.jobs.size.should == 1
#    end
#
#    it 'raises on negative frequencies' do
#
#      lambda {
#        @scheduler.every(-1) do
#        end
#      }.should raise_error(ArgumentError)
#    end
#
#    it 'raises on zero frequencies' do
#
#      lambda {
#        @scheduler.every(0) do
#        end
#      }.should raise_error(ArgumentError)
#    end
#
#    it 'does not reschedule if the job was unscheduled' do
#
#      counter = 0
#
#      job =
#        @scheduler.schedule_every '0.5s' do
#          counter = counter + 1
#        end
#
#      sleep 1.6
#
#      job.unschedule
#      c = counter
#
#      sleep 1.6
#
#      counter.should == c
#    end
#
#    it 'raises if the job frequency is higher than the scheduler frequency' do
#
#      @scheduler.frequency = 10
#
#      lambda {
#        @scheduler.every '1s' do; end
#      }.should raise_error(ArgumentError)
#    end
  end

  describe '#schedule_interval' do

    it 'accepts a duration string' do

      job = @scheduler.schedule_interval('1h') do; end

      job.interval.should == 3600
    end
  end
end

describe Rufus::Scheduler::IntervalJob do

  before :each do
    @scheduler = Rufus::Scheduler.new
  end
  after :each do
    @scheduler.shutdown
  end

  describe '#interval' do

    it 'returns the scheduled interval' do

      job = @scheduler.schedule_interval('1h') do; end

      job.interval.should == 3600
    end
  end
end

