
#
# Specifying rufus-scheduler
#
# Wed Apr 17 06:00:59 JST 2013
#

require 'spec_helper'


describe Rufus::Scheduler::Job do

  # specify behaviours common to all job classes

  before :each do
    @scheduler = Rufus::Scheduler.new
  end
  after :each do
    @scheduler.shutdown
  end

  describe '#last_time' do

    it 'returns nil if the job never fired' do

      job = @scheduler.schedule_in '10d' do; end

      job.last_time.should == nil
    end

    it 'returns the last time the job fired' do

      job = @scheduler.schedule_in '0s' do; end

      sleep 0.4

      job.last_time.should_not == nil
    end
  end

  describe '#threads' do

    it 'returns an empty list when the job is not running' do

      job = @scheduler.in('1d', :job => true) {}

      job.threads.size.should == 0
    end

    it 'returns an empty list after the job terminated' do

      job = @scheduler.in('0s', :job => true) {}

      sleep 0.8

      job.threads.size.should == 0
    end

    it 'lists the threads the job currently runs in' do

      job =
        @scheduler.schedule_in('0s') do
          sleep(1)
        end

      sleep 0.4

      job.threads.size.should == 1

      t = job.threads.first
      t[job.thread_key].should_not == nil
    end
  end

  describe '#kill' do

    it 'has no effect if the job is not running' do

      job = @scheduler.schedule_in '10d' do; end

      tls = Thread.list.size

      job.kill

      Thread.list.size.should == tls
    end

    it 'kills all the threads of the job' do

      counter = 0

      job =
        @scheduler.schedule_every '0.5s' do
          sleep 2
          counter = counter + 1
        end

      sleep 1

      job.kill

      sleep 2

      counter.should == 0
    end
  end

  describe '#thread_values' do

    it 'lists the thread values set by the job' do

      job =
        @scheduler.in('0s', :job => true, :blocking => true) do
          sleep(1)
        end

      sleep 0.4

      job.thread_values.size.should == 1

      tv = job.thread_values.first
      tv.keys.sort_by { |k| k.to_s }.should == [ :job, :timestamp ]
      tv[:job].should == job
    end
  end

  describe '#running?' do

    it 'returns false when the job is not running in any thread' do

      job = @scheduler.in('1d', :job => true) {}

      job.running?.should == false
    end

    it 'returns true when the job is running in at least one thread' do

      job = @scheduler.in('0s', :job => true) { sleep(1) }

      sleep 0.4

      job.running?.should == true
    end
  end

  context ':tag / :tags => [ t0, t1 ]' do

    it 'accepts one tag' do

      job = @scheduler.in '10d', :job => true, :tag => 't0' do; end

      job.tags.should == %w[ t0 ]
    end

    it 'accepts an array of tags' do

      job = @scheduler.in '10d', :job => true, :tag => %w[ t0 t1 ] do; end

      job.tags.should == %w[ t0 t1 ]
    end

    it 'turns tags into strings' do

      job = @scheduler.in '10d', :job => true, :tags => [ 1, 2 ] do; end

      job.tags.should == %w[ 1 2 ]
    end
  end

  context ':blocking => true' do

    it 'runs the job in the same thread as the scheduler thread' do

      job =
        @scheduler.in('0s', :job => true, :blocking => true) do
          sleep(1)
        end

      sleep 0.4

      job.threads.first.should == @scheduler.thread

      sleep 1.4

      job.threads.size.should == 0
    end
  end

  context 'default one thread per job behaviour' do

    it 'runs the job in a dedicated thread' do

      job =
        @scheduler.in('0s', :job => true) do
          sleep(1)
        end

      sleep 0.4

      job.threads.first.should_not == @scheduler.thread

      sleep 1.4

      job.threads.size.should == 0
    end
  end

  context ':allow_overlapping / :allow_overlap / :overlap' do

    context 'default (:overlap => true)' do

      it 'lets a job overlap itself' do

        job =
          @scheduler.every('0.100', :job => true) do
            sleep(5)
          end

        sleep 3

        job.threads.size.should > 1
      end
    end

    context 'when :overlap => false' do

      it 'prevents a job from overlapping itself' do

        job =
          @scheduler.every('0.100', :job => true, :overlap => false) do
            sleep(5)
          end

        sleep 3

        job.threads.size.should == 1
      end
    end
  end

  context ':mutex' do

    context ':mutex => "mutex_name"' do

      it 'prevents concurrent executions' do

        j0 =
          @scheduler.in('0s', :job => true, :mutex => 'vladivostok') do
            sleep(3)
          end
        j1 =
          @scheduler.in('0s', :job => true, :mutex => 'vladivostok') do
            sleep(3)
          end

        sleep 0.4

        if j0.threads.any?
          j0.threads.size.should == 1
          j1.threads.size.should == 0
        else
          j0.threads.size.should == 0
          j1.threads.size.should == 1
        end

        @scheduler.mutexes.keys.should == %w[ vladivostok ]
      end
    end

    context ':mutex => mutex_instance' do

      it 'prevents concurrent executions' do

        m = Mutex.new

        j0 = @scheduler.in('0s', :job => true, :mutex => m) { sleep(3) }
        j1 = @scheduler.in('0s', :job => true, :mutex => m) { sleep(3) }

        sleep 0.4

        if j0.threads.any?
          j0.threads.size.should == 1
          j1.threads.size.should == 0
        else
          j0.threads.size.should == 0
          j1.threads.size.should == 1
        end

        @scheduler.mutexes.keys.should == []
      end
    end

    context ':mutex => [ array_of_mutex_names_or_instances ]' do

      it 'prevents concurrent executions' do

        j0 =
          @scheduler.in('0s', :job => true, :mutex => %w[ a b ]) do
            sleep(3)
          end
        j1 =
          @scheduler.in('0s', :job => true, :mutex => %w[ a b ]) do
            sleep(3)
          end

        sleep 0.4

        if j0.threads.any?
          j0.threads.size.should == 1
          j1.threads.size.should == 0
        else
          j0.threads.size.should == 0
          j1.threads.size.should == 1
        end

        @scheduler.mutexes.keys.sort.should == %w[ a b ]
      end
    end
  end

  context ':timeout => duration_or_point_in_time' do

    it 'is set at schedule time' do

      job = @scheduler.schedule_in '10d', :timeout => '1d' do; end

      job.opts[:timeout].should == '1d'
      job.timeout.should == 86400.0
    end

    it 'interrupts the job it is stashed to (duration)' do

      counter = 0
      toe = nil

      job =
        @scheduler.schedule_in '0s', :timeout => '1s' do
          begin
            counter = counter + 1
            sleep 1.5
            counter = counter + 1
          rescue Rufus::Scheduler::TimeoutError => e
            toe = e
          end
        end

      sleep(3)

      counter.should == 1
      toe.class.should == Rufus::Scheduler::TimeoutError
    end

    it 'interrupts the job it is stashed to (point in time)' do

      counter = 0

      job =
        @scheduler.schedule_in '0s', :timeout => Time.now + 1 do
          begin
            counter = counter + 1
            sleep 1.5
            counter = counter + 1
          rescue Rufus::Scheduler::TimeoutError => e
          end
        end

      sleep(3)

      counter.should == 1
    end
  end
end

