
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

  describe '#at' do

    it 'raises if the block to schedule is missing' do

      lambda {
        @scheduler.at(Time.now + 3600)
      }.should raise_error(ArgumentError)
    end

    it 'returns a job id' do

      job_id =
        @scheduler.at(Time.now + 3600) do
        end

      job_id.class.should == String
      job_id.should match(/^at_/)
    end

    it 'returns a job if :job => true' do

      job =
        @scheduler.at(Time.now + 3600, :job => true) do
        end

      job.class.should == Rufus::Scheduler::AtJob
    end

    it 'adds a job' do

      t = Time.now + 3600

      @scheduler.at(t) do
      end

      @scheduler.jobs.size.should == 1
      @scheduler.jobs.first.class.should == Rufus::Scheduler::AtJob
      @scheduler.jobs.first.time.should == t
    end

    it 'triggers a job' do

      a = false

      @scheduler.at(Time.now + 0.100) do
        a = true
      end

      sleep 0.4

      a.should == true
    end

    it 'removes the job after execution' do

      @scheduler.at(Time.now + 0.100) do
      end

      sleep 0.4

      @scheduler.jobs.size.should == 0
    end

    it 'accepts a Time instance' do

      t = Time.now + 3600

      job = @scheduler.at(t, :job => true) {}

      job.time.should == t
    end

    it 'accepts a time string' do

      job = @scheduler.at('2100-12-12 20:30', :job => true) {}

      job.time.should == Time.parse('2100-12-12 20:30')
    end

    it 'accepts a time string with a delta timezone' do

      job = @scheduler.at('2100-12-12 20:30 -0200', :job => true) {}

      job.time.should == Time.parse('2100-12-12 20:30 -0200')
    end

    it 'accepts a time string with a named timezone' do

      job = @scheduler.at('2050-12-12 20:30 Europe/Berlin', :job => true) {}

      job.time.strftime('%c %z').should == 'Mon Dec 12 19:30:00 2050 +0000'
    end

    it 'accepts a Chronic time string (if Chronic is present)'
    it 'accepts an ActiveSupport time thinggy'
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

