
#
# Specifying rufus-scheduler
#
# Wed Apr 27 00:51:07 JST 2011
#

require 'spec_base'


describe 'job classes' do

  before(:each) do
    @s = start_scheduler
  end
  after(:each) do
    stop_scheduler(@s)
  end

  describe Rufus::Scheduler::Job do

    describe '#running' do

      it 'returns false when the job is inactive' do

        job = @s.in '2d' do
        end

        job.running.should == false
      end

      it 'returns true when the job is active' do

        job = @s.in 0 do
          sleep(100)
        end

        wait_next_tick

        job.running.should == true
      end

      it 'returns false when the job hits some error' do

        $exception = nil

        def @s.handle_exception(j, e)
          #p e
          $exception = e
        end

        job = @s.in 0 do
          raise "nada"
        end

        wait_next_tick

        $exception.should_not == nil
        job.running.should == false
      end
    end

    describe '#running?' do

      it 'is an alias for #running' do

        job = @s.in 0 do
          sleep(100)
        end

        wait_next_tick

        job.running?.should == true
      end
    end
  end

  describe Rufus::Scheduler::AtJob do

    describe '#unschedule' do

      it 'removes the job from the scheduler' do

        job = @s.at Time.now + 3 * 3600 do
        end

        wait_next_tick

        job.unschedule

        @s.jobs.size.should == 0
      end
    end

    describe '#next_time' do

      it 'returns the time when the job will trigger' do

        t = Time.now + 3 * 3600

        job = @s.at Time.now + 3 * 3600 do
        end

        job.next_time.class.should == Time
        job.next_time.to_i.should == t.to_i
      end
    end
  end

  describe Rufus::Scheduler::InJob do

    describe '#unschedule' do

      it 'removes the job from the scheduler' do

        job = @s.in '2d' do
        end

        wait_next_tick

        job.unschedule

        @s.jobs.size.should == 0
      end
    end

    describe '#next_time' do

      it 'returns the time when the job will trigger' do

        t = Time.now + 3 * 3600

        job = @s.in '3h' do
        end

        job.next_time.class.should == Time
        job.next_time.to_i.should == t.to_i
      end
    end
  end

  describe Rufus::Scheduler::EveryJob do

    describe '#next_time' do

      it 'returns the time when the job will trigger' do

        t = Time.now + 3 * 3600

        job = @s.every '3h' do
        end

        job.next_time.class.should == Time
        job.next_time.to_i.should == t.to_i
      end
    end

    describe '#paused?' do

      it 'returns false initially' do

        job = @s.every '3h' do; end

        job.paused?.should == false
      end
    end

    describe '#pause' do

      it 'pauses the job' do

        job = @s.every '3h' do; end

        job.pause

        job.paused?.should == true
      end
    end

    describe '#resume' do

      it 'resumes the job' do

        job = @s.every '3h' do; end

        job.resume

        job.paused?.should == false
      end
    end
  end

  describe Rufus::Scheduler::CronJob do

    describe '#next_time' do

      it 'returns the time when the job will trigger' do

        job = @s.cron '* * * * *' do
        end

        job.next_time.class.should == Time
        (job.next_time.to_i - Time.now.to_i).should satisfy { |v| v < 60 }
      end
    end

    describe '#paused?' do

      it 'returns false initially' do

        job = @s.cron '* * * * *' do; end

        job.paused?.should == false
      end
    end

    describe '#pause' do

      it 'pauses the job' do

        job = @s.cron '* * * * *' do; end

        job.pause

        job.paused?.should == true
      end
    end

    describe '#resume' do

      it 'resumes the job' do

        job = @s.cron '* * * * *' do; end

        job.resume

        job.paused?.should == false
      end
    end
  end
end

