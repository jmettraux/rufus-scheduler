
require 'spec_helper'


describe Rufus::Scheduler do

  before :each do
    @scheduler = Rufus::Scheduler.new
  end
  after :each do
    @scheduler.shutdown
  end

  describe '#at' do

    it 'raises if the block to schedule is missing' do

      lambda {
        @scheduler.at(Time.now + 3600)
      }.should raise_error(ArgumentError)
    end

    it 'returns a job id' do

      job_id = @scheduler.at(Time.now + 3600) do
      end

      job_id.class.should == String
      job_id.should match(/^at_/)
    end

    it 'adds a job' do

      t = Time.now + 3600

      @scheduler.at(t) do
      end

      sleep 0.4

      @scheduler.jobs.size.should == 1
      @scheduler.jobs.first.class.should == Rufus::Scheduler::AtJob
      @scheduler.jobs.first.time.should == t
    end

    it 'removes the job after execution' do

      @scheduler.at(Time.now + 0.100) do
      end

      sleep 0.7

      @scheduler.jobs.size.should == 0
    end
  end

  describe '#schedule_at' do

    it 'returns a job' do

      job = @scheduler.schedule_at(Time.now + 3600) do
      end

      job.class.should == Rufus::Scheduler::AtJob
      job.id.should match(/^at_/)
    end
  end
end

