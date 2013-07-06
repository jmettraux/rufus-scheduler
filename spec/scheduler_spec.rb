
#
# Specifying rufus-scheduler
#
# Wed Apr 17 06:00:59 JST 2013
#

require 'spec_helper'


describe Rufus::Scheduler do

  describe '#initialize' do

    it 'starts the scheduler thread' do

      scheduler = Rufus::Scheduler.new

      t = Thread.list.find { |t|
        t[:name] == "rufus_scheduler_#{scheduler.object_id}"
      }

      t[:rufus_scheduler].should == scheduler
    end

    it 'sets a :rufus_scheduler thread local var' do

      scheduler = Rufus::Scheduler.new
    end

    it 'accepts a :frequency option' do

      scheduler = Rufus::Scheduler.new(:frequency => 2)

      scheduler.frequency.should == 2
    end

    it 'accepts a :thread_name option' do

      scheduler = Rufus::Scheduler.new(:thread_name => 'oliphant')

      t = Thread.list.find { |t| t[:name] == 'oliphant' }

      t[:rufus_scheduler].should == scheduler
    end
  end

  context 'instance methods' do

    before :each do
      @scheduler = Rufus::Scheduler.new
    end
    after :each do
      @scheduler.shutdown
    end

    describe '#uptime' do

      it 'returns the uptime as a float' do

        @scheduler.uptime.should > 0.0
      end
    end

    describe '#uptime_s' do

      it 'returns the uptime as a human readable string' do

        sleep 1

        @scheduler.uptime_s.should match(/^[12]s\d+$/)
      end
    end

    describe '#join' do

      it 'joins the scheduler thread' do

        pending
        @scheduler.respond_to?(:join).should == true # oh, well...
      end
    end

    #--
    # management methods
    #++

    describe '#shutdown' do

      it 'blanks the uptime' do

        scheduler = Rufus::Scheduler.new
        scheduler.shutdown

        scheduler.uptime.should == nil
      end

      it 'terminates the scheduler' do

        scheduler = Rufus::Scheduler.new
        scheduler.shutdown

        sleep 0.100
        sleep 0.400 if RUBY_VERSION < '1.9.0'

        t = Thread.list.find { |t|
          t[:name] == "rufus_scheduler_#{scheduler.object_id}"
        }

        t.should == nil
      end

      it 'has a #stop alias' do

        scheduler = Rufus::Scheduler.new
        scheduler.shutdown

        scheduler.uptime.should == nil
      end

      #it 'has a #close alias'
    end

    describe '#pause' do
      it 'works'
    end
    describe '#resume' do
      it 'works'
    end

    #--
    # job methods
    #++

    describe '#jobs' do

      it 'is empty at the beginning' do

        scheduler = Rufus::Scheduler.new

        scheduler.jobs.should == []
      end
    end

    describe '#every_jobs' do
      it 'works'
    end
    describe '#at_jobs' do
      it 'works'
    end
    describe '#in_jobs' do
      it 'works'
    end
    describe '#cron_jobs' do
      it 'works'
    end
  end
end

