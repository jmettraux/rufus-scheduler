
#
# Specifying rufus-scheduler
#
# Wed Apr 17 06:00:59 JST 2013
#

require 'spec_helper'


describe Rufus::Scheduler::AtJob do

  before :each do
    @scheduler = Rufus::Scheduler.new
  end
  after :each do
    @scheduler.shutdown
  end

  describe '#unschedule' do

    it 'unschedules the job' do

      job = @scheduler.at(Time.now + 3600, :job => true) do
      end

      job.unschedule

      sleep 0.4

      @scheduler.jobs.size.should == 0
    end
  end

  describe '#scheduled_at' do

    it 'returns the Time at which the job got scheduled' do

      job = @scheduler.schedule_at((t = Time.now) + 3600) {}

      job.scheduled_at.to_i.should >= t.to_i - 1
      job.scheduled_at.to_i.should <= t.to_i + 1
    end
  end

  describe '#time' do

    it 'returns the time at which the job will trigger' do

      t = Time.now + 3600

      job = @scheduler.schedule_at t do; end

      job.time.should == t
    end
  end
end

