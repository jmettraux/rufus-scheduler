
#
# Specifying rufus-scheduler
#
# Sat Mar 21 17:43:23 JST 2009
#

require 'spec_base'


describe SCHEDULER_CLASS do

  it 'stops' do

    var = nil

    s = start_scheduler
    s.in('3s') { var = true }

    stop_scheduler(s)

    var.should == nil
    sleep 4
    var.should == nil
  end

  unless SCHEDULER_CLASS == Rufus::Scheduler::EmScheduler

    it 'sets a default scheduler thread name' do

      s = start_scheduler

      s.instance_variable_get(:@thread)['name'].should match(
        /Rufus::Scheduler::.*Scheduler - \d+\.\d+\.\d+/)

      stop_scheduler(s)
    end

    it 'sets the scheduler thread name' do

      s = start_scheduler(:thread_name => 'nada')
      s.instance_variable_get(:@thread)['name'].should == 'nada'

      stop_scheduler(s)
    end
  end

  it 'accepts a custom frequency' do

    var = nil

    s = start_scheduler(:frequency => 3.0)

    s.in('1s') { var = true }

    sleep 1
    var.should == nil

    sleep 1
    var.should == nil

    sleep 2
    var.should == true

    stop_scheduler(s)
  end

  context 'pause/resume' do

    before(:each) do
      @s = start_scheduler
    end
    after(:each) do
      stop_scheduler(@s)
    end

    describe '#pause' do

      it 'pauses a job (every)' do

        $count = 0

        j = @s.every '1s' do
          $count = $count + 1
        end

        @s.pause(j.job_id)

        sleep 2.5

        j.paused?.should == true
        $count.should == 0
      end

      it 'pauses a job (cron)' do

        $count = 0

        j = @s.cron '* * * * * *' do
          $count = $count + 1
        end

        @s.pause(j.job_id)

        sleep 2.5

        j.paused?.should == true
        $count.should == 0
      end
    end

    describe '#resume' do

      it 'resumes a job (every)' do

        $count = 0

        j = @s.every '1s' do
          $count = $count + 1
        end

        @s.pause(j.job_id)

        sleep 2.5

        c = $count

        @s.resume(j.job_id)

        sleep 1.5

        j.paused?.should == false
        ($count > c).should == true
      end

      it 'pauses a job (cron)' do

        $count = 0

        j = @s.cron '* * * * * *' do
          $count = $count + 1
        end

        @s.pause(j.job_id)

        sleep 2.5

        c = $count

        @s.resume(j.job_id)

        sleep 1.5

        j.paused?.should == false
        ($count > c).should == true
      end
    end
  end

  context 'trigger threads' do

    before(:each) do
      @s = start_scheduler
    end
    after(:each) do
      stop_scheduler(@s)
    end

    describe '#trigger_threads' do

      it 'returns an empty list when no jobs are running' do

        @s.trigger_threads.should == []
      end

      it 'returns a list of the threads of the running jobs' do

        @s.in('100') { sleep 10 }

        sleep 0.5

        @s.trigger_threads.collect { |e| e.class }.should == [ Thread ]
      end
    end

    describe '#running_jobs' do

      it 'returns an empty list when no jobs are running' do

        @s.running_jobs.should == []
      end

      it 'returns a list of the currently running jobs' do

        job = @s.in('100') { sleep 10 }

        sleep 0.5

        @s.running_jobs.should == [ job ]
      end
    end
  end
end

describe 'Rufus::Scheduler#start_new' do

  it 'piggybacks EM if present and running' do

    s = Rufus::Scheduler.start_new

    s.class.should == SCHEDULER_CLASS

    stop_scheduler(s)
  end
end

