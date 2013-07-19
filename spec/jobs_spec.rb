
#
# Specifying rufus-scheduler
#
# Wed Apr 17 06:00:59 JST 2013
#

require 'spec_helper'


describe Rufus::Scheduler::Job do

  before :each do
    @scheduler = Rufus::Scheduler.new
  end
  after :each do
    @scheduler.shutdown
  end

  describe Rufus::Scheduler::Job do
  end

  describe Rufus::Scheduler::OneTimeJob do
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

    describe '#scheduled_at' do

      it 'returns the Time at which the job got scheduled' do

        job = @scheduler.schedule_at((t = Time.now) + 3600) {}

        job.scheduled_at.to_i.should >= t.to_i - 1
        job.scheduled_at.to_i.should <= t.to_i + 1
      end
    end
  end

  describe Rufus::Scheduler::InJob do
  end

  describe Rufus::Scheduler::RepeatJob do

    describe '#pause' do

      it 'pauses the job' do

        counter = 0

        job =
          @scheduler.schedule_every('0.5s') do
            counter += 1
          end

        counter.should == 0

        while counter < 1; sleep(0.1); end

        job.pause

        sleep(1)

        counter.should == 1
      end
    end

    describe '#paused?' do

      it 'returns true if the job is paused' do

        job = @scheduler.schedule_every('10s') do; end

        job.pause

        job.paused?.should == true
      end

      it 'returns false if the job is not paused' do

        job = @scheduler.schedule_every('10s') do; end

        job.paused?.should == false
      end
    end

    describe '#resume' do

      it 'resumes a paused job' do

        counter = 0

        job =
          @scheduler.schedule_every('0.5s') do
            counter += 1
          end

        job.pause
        job.resume

        sleep(1.5)

        counter.should > 1
      end

      it 'has no effect on a not paused job' do

        job = @scheduler.schedule_every('10s') do; end

        job.resume

        job.paused?.should == false
      end
    end

    describe ':times => i' do

      it 'lets a job unschedule itself after i times' do

        counter = 0

        job =
          @scheduler.schedule_every '0.5s', :times => 3 do
            counter = counter + 1
          end

        sleep(2.5)

        counter.should == 3
      end

      it 'is OK when passed a nil instead of an integer' do

        counter = 0

        job =
          @scheduler.schedule_every '0.5s', :times => nil do
            counter = counter + 1
          end

        sleep(2.5)

        counter.should > 3
      end

      it 'raises when passed something else than nil or an integer' do

        lambda {
          @scheduler.schedule_every '0.5s', :times => 'nada' do; end
        }.should raise_error(ArgumentError)
      end
    end

    describe ':first/:first_in/:first_at => point in time' do

      it 'accepts a Time instance' do

        t = Time.now + 10

        job = @scheduler.schedule_every '0.5s', :first => t do; end

        job.first_at.should == t
      end

      it 'only lets the job trigger after the :first' do

        t = Time.now + 1.4
        counter = 0

        job =
          @scheduler.schedule_every '0.5s', :first => t do
            counter = counter + 1
          end

        sleep(1)

        counter.should == 0

        sleep(1)

        counter.should > 0
      end
    end

    describe ':first/:first_in/:first_at => duration' do

      it 'accepts a duration string' do

        t = Time.now

        job = @scheduler.schedule_every '0.5s', :first => '1h' do; end

        job.first_at.should > t + 3600
        job.first_at.should < t + 3601
      end

      it 'accepts a duration in seconds' do

        t = Time.now

        job = @scheduler.schedule_every '0.5s', :first => 3600 do; end

        job.first_at.should > t + 3600
        job.first_at.should < t + 3601
      end

      it 'raises if the argument is worthless' do

        lambda {
          @scheduler.every '0.5s', :first => :nada do; end
        }.should raise_error(ArgumentError)
      end
    end
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

