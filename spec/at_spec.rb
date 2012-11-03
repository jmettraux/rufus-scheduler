
require 'spec_helper'


describe Rufus::Scheduler do

  before :each do
    @scheduler = Rufus::Scheduler.new
  end
  after :each do
    @scheduler.shutdown
  end

  describe '#at' do

    it 'raises if the block to schedule is missing'

    it 'returns a job id' do

      job_id = @scheduler.at(Time.now + 3600) do
      end

      job_id.class.should == String
      job_id.should match(/^at_/)
    end

    it 'adds a job'
    it 'removes the job after execution'
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

