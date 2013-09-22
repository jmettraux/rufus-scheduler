
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

  describe '#in' do

    it 'adds a job' do

      @scheduler.in(3600) do
      end

      @scheduler.jobs.size.should == 1
      @scheduler.jobs.first.class.should == Rufus::Scheduler::InJob
    end

    it 'triggers a job' do

      a = false

      @scheduler.in(0.4) do
        a = true
      end

      sleep 0.9

      a.should == true
    end

    it 'removes the job after execution' do

      @scheduler.in(0.4) do
      end

      sleep 0.700

      @scheduler.jobs.size.should == 0
    end
  end

  describe '#schedule_in' do

    it 'accepts a number' do

      job = @scheduler.schedule_in(3600) {}

      job.original.should == 3600
    end

    it 'accepts a duration string' do

      job = @scheduler.schedule_in('1h') {}

      job.original.should == '1h'
      job.time.should >= job.scheduled_at + 3509
      job.time.should <= job.scheduled_at + 3601
    end

    it 'accepts an ActiveSupport .from_now thinggy'
      #
      #   schedule_in(2.days.from_now)
      #
      # that'd simply require "in" to be a bit like "at"...
  end
end

