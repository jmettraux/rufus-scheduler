
#
# Specifying rufus-scheduler
#
# Wed Apr 17 06:00:59 JST 2013
#

require 'spec_helper'


describe Rufus::Scheduler do

  before :each do
    @scheduler = Rufus::Scheduler.new
  end
  after :each do
    @scheduler.shutdown
  end

  describe '#every' do

    it 'adds a job' do

      @scheduler.every(10) do
      end

      @scheduler.jobs.size.should == 1
      @scheduler.jobs.first.class.should == Rufus::Scheduler::EveryJob
    end

    it 'triggers a job (2 times)' do

      counter = 0

      @scheduler.every(0.4) do
        counter += 1
      end

      sleep 2.0

      counter.should > 2
    end

    it 'does not remove the job after execution' do

      @scheduler.every(0.4) do
      end

      sleep 0.9

      @scheduler.jobs.size.should == 1
    end

    it 'raises on negative frequencies' do

      lambda {
        @scheduler.every(-1) do
        end
      }.should raise_error(ArgumentError)
    end

    it 'raises on zero frequencies' do

      lambda {
        @scheduler.every(0) do
        end
      }.should raise_error(ArgumentError)
    end

    it 'does not reschedule if the job was unscheduled' do

      counter = 0

      job =
        @scheduler.schedule_every '0.5s' do
          counter = counter + 1
        end

      sleep 1.6

      job.unschedule
      c = counter

      sleep 1.6

      counter.should == c
    end

    it 'raises if the job frequency is higher than the scheduler frequency' do

      @scheduler.frequency = 10

      lambda {
        @scheduler.every '1s' do; end
      }.should raise_error(ArgumentError)
    end
  end

  describe '#schedule_every' do

    it 'accepts a duration string' do

      job = @scheduler.schedule_every('1h') do; end

      job.frequency.should == 3600.0
    end
  end
end

