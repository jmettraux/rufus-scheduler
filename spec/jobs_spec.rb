
require 'spec_helper'


describe Rufus::Scheduler::Job do

  before :each do
    @scheduler = Rufus::Scheduler.new
  end
  after :each do
    @scheduler.shutdown
  end

  describe Rufus::Scheduler::AtJob do

    describe '#unschedule' do

      it 'unschedules the job' do

        job = @scheduler.at(Time.now + 3600, :job => true) do
        end

        job.unschedule

        sleep 0.4

        @scheduler.jobs.size.should == 0
      end
    end
  end

  describe Rufus::Scheduler::InJob do

    #describe '#unschedule' do
    #  it 'unschedules the job'
    #end
  end

  describe Rufus::Scheduler::EveryJob do

    #describe '#unschedule' do
    #  it 'unschedules the job'
    #end
  end

  describe Rufus::Scheduler::CronJob do

    #describe '#unschedule' do
    #  it 'unschedules the job'
    #end
  end
end

