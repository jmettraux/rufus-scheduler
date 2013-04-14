
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

      sleep 0.4

      @scheduler.jobs.size.should == 1
      @scheduler.jobs.first.class.should == Rufus::Scheduler::EveryJob
    end

    it 'triggers a job (2 times)' do

      $counter = 0

      @scheduler.every(0.1) do
        $counter += 1
      end

      sleep 0.4

      $counter.should > 2
    end

    it 'does not remove the job after execution' do
      pending

      @scheduler.in(0.4) do
      end

      sleep 0.700

      @scheduler.jobs.size.should == 0
    end
  end

  describe '#schedule_every' do

    pending 'it accepts a duration string'
  end
end

