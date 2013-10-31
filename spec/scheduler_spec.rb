
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
        t[:name] == "rufus_scheduler_#{scheduler.object_id}_scheduler"
      }

      t[:rufus_scheduler].should == scheduler
    end

    it 'sets a :rufus_scheduler thread local var' do

      scheduler = Rufus::Scheduler.new
    end

    it 'accepts a :frequency => integer option' do

      scheduler = Rufus::Scheduler.new(:frequency => 2)

      scheduler.frequency.should == 2
    end

    it 'accepts a :frequency => "2h1m" option' do

      scheduler = Rufus::Scheduler.new(:frequency => '2h1m')

      scheduler.frequency.should == 3600 * 2 + 60
    end

    it 'accepts a :thread_name option' do

      scheduler = Rufus::Scheduler.new(:thread_name => 'oliphant')

      t = Thread.list.find { |t| t[:name] == 'oliphant' }

      t[:rufus_scheduler].should == scheduler
    end

    #it 'accepts a :min_work_threads option' do
    #  scheduler = Rufus::Scheduler.new(:min_work_threads => 9)
    #  scheduler.min_work_threads.should == 9
    #end

    it 'accepts a :max_work_threads option' do

      scheduler = Rufus::Scheduler.new(:max_work_threads => 9)

      scheduler.max_work_threads.should == 9
    end
  end

  before :each do
    @scheduler = Rufus::Scheduler.new
  end
  after :each do
    @scheduler.shutdown
  end

  describe 'a schedule method' do

    it 'passes the job to its block when it triggers' do

      j = nil
      job = @scheduler.schedule_in('0s') { |jj| j = jj }

      sleep 0.4

      j.should == job
    end

    it 'passes the trigger time as second block argument' do

      t = nil
      @scheduler.schedule_in('0s') { |jj, tt| t = tt }

      sleep 0.4

      t.class.should == Time
    end

    class MyHandler
      attr_reader :counter
      def initialize
        @counter = 0
      end
      def call(job, time)
        @counter = @counter + 1
      end
    end

    it 'accepts a callable object instead of a block' do

      mh = MyHandler.new

      @scheduler.schedule_in('0s', mh)

      sleep 0.4

      mh.counter.should == 1
    end

    class MyOtherHandler
      attr_reader :counter
      def initialize
        @counter = 0
      end
      def call
        @counter = @counter + 1
      end
    end

    it 'accepts a callable obj instead of a block (#call with no args)' do

      job = @scheduler.schedule_in('0s', MyOtherHandler.new)

      sleep 0.4

      job.handler.counter.should == 1
    end

    it 'accepts a class as callable' do

      job =
        @scheduler.schedule_in('0s', Class.new do
          attr_reader :value
          def call
            @value = 7
          end
        end)

      sleep 0.4

      job.handler.value.should == 7
    end

    it 'raises if the scheduler is shutting down' do

      @scheduler.shutdown

      lambda {
        @scheduler.in('0s') { puts 'hhhhhhhhhhhello!!' }
      }.should raise_error(Rufus::Scheduler::NotRunningError)
    end
  end

  describe '#in / #at' do

    # scheduler.in(2.hours.from_now) { ... }

    it 'accepts point in time and duration indifferently (#in)' do

      seen = false

      t = Time.now + 1

      @scheduler.in(t) { seen = true }

      sleep 0.1 while seen != true
    end

    it 'accepts point in time and duration indifferently (#at)' do

      seen = false

      t = 1

      @scheduler.at(t) { seen = true }

      sleep 0.1 while seen != true
    end
  end

  describe '#schedule' do

    it 'accepts a duration and schedules an InJob' do

      j = @scheduler.schedule '1s' do; end

      j.class.should == Rufus::Scheduler::InJob
      j.original.should == '1s'
    end

    it 'accepts a point in time and schedules an AtJob' do

      j = @scheduler.schedule '2070/12/24 23:00' do; end

      j.class.should == Rufus::Scheduler::AtJob
      j.next_time.strftime('%Y %m %d').should == '2070 12 24'
    end

    it 'accepts a cron string and schedules a CronJob' do

      j = @scheduler.schedule '* * * * *' do; end

      j.class.should == Rufus::Scheduler::CronJob
    end
  end

  describe '#repeat' do

    it 'accepts a duration and schedules an EveryJob' do

      j = @scheduler.repeat '1s' do; end

      j.class.should == Rufus::Scheduler::EveryJob
    end

    it 'accepts a cron string and schedules a CronJob' do

      j = @scheduler.repeat '* * * * *' do; end

      j.class.should == Rufus::Scheduler::CronJob
    end
  end

  describe '#unschedule(job_or_work_id)' do

    it 'accepts job ids' do

      job = @scheduler.schedule_in '10d' do; end

      job.unscheduled_at.should == nil

      @scheduler.unschedule(job.id)

      job.unscheduled_at.should_not == nil
    end

    it 'accepts jobs' do

      job = @scheduler.schedule_in '10d' do; end

      job.unscheduled_at.should == nil

      @scheduler.unschedule(job)

      job.unscheduled_at.should_not == nil
    end

    it 'carefully unschedules repeat jobs' do

      counter = 0

      job =
        @scheduler.schedule_every '0.5s' do
          counter = counter + 1
        end

      sleep 1.5
      c = counter

      @scheduler.unschedule(job)

      sleep 1.5
      counter.should == c
    end
  end

  describe '#uptime' do

    it 'returns the uptime as a float' do

      @scheduler.uptime.should >= 0.0
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

      t = Thread.new { @scheduler.join; Thread.current['a'] = 'over' }

      t['a'].should == nil

      @scheduler.shutdown

      sleep(1)

      t['a'].should == 'over'
    end
  end

  describe '#job(job_id)' do

    it 'returns nil if there is no corresponding Job instance' do

      @scheduler.job('nada').should == nil
    end

    it 'returns the corresponding Job instance' do

      job_id = @scheduler.in '10d' do; end

      sleep(1) # give it some time to get scheduled

      @scheduler.job(job_id).job_id.should == job_id
    end
  end

#    describe '#find_by_tag(t)' do
#
#      it 'returns an empty list when there are no jobs with the given tag' do
#
#        @scheduler.find_by_tag('nada').should == []
#      end
#
#      it 'returns all the jobs with the given tag' do
#
#        @scheduler.in '10d', :tag => 't0' do; end
#        @scheduler.every '2h', :tag => %w[ t0 t1 ] do; end
#        @scheduler.every '3h' do; end
#
#        @scheduler.find_by_tag('t0').map(&:original).should ==
#          %w[ 2h 10d ]
#        @scheduler.find_by_tag('t1').map(&:original).should ==
#          %w[ 2h ]
#        @scheduler.find_by_tag('t1', 't0').map(&:original).sort.should ==
#          %w[ 2h ]
#      end
#    end

  describe '#threads' do

    it 'just lists the main thread (scheduler thread) when no job is scheduled' do

      @scheduler.threads.should == [ @scheduler.thread ]
    end

    it 'lists all the threads a scheduler uses' do

      @scheduler.in '0s' do
        sleep(2)
      end

      sleep 0.4

      @scheduler.threads.size.should == 2
    end
  end

  describe '#work_threads(:all)' do

    it 'returns an empty array when the scheduler has not yet done anything' do

      @scheduler.work_threads.should == []
    end

    it 'lists all the work threads in the pool' do

      @scheduler.in '0s' do
        sleep(0.2)
      end
      @scheduler.in '0s' do
        sleep(2.0)
      end

      sleep 0.6

      @scheduler.work_threads.size.should == 2
      @scheduler.work_threads(:all).size.should == 2
    end
  end

  describe '#work_threads(:vacant)' do

    it 'returns an empty array when the scheduler has not yet done anything' do

      @scheduler.work_threads(:vacant).should == []
    end

    it 'lists all the vacant work threads in the pool' do

      @scheduler.in '0s' do
        sleep(0.2)
      end
      @scheduler.in '0s' do
        sleep(2.0)
      end

      sleep 0.6

      @scheduler.work_threads(:all).size.should == 2
      @scheduler.work_threads(:vacant).size.should == 1
    end
  end

  describe '#work_threads(:active)' do

    it 'returns [] when there are no jobs running' do

      @scheduler.work_threads(:active).should == []
    end

    it 'returns the list of threads of the running jobs' do

      job =
        @scheduler.schedule_in('0s') do
          sleep 1
        end

      sleep 0.4

      @scheduler.work_threads(:active).size.should == 1

      t = @scheduler.work_threads(:active).first

      t.class.should == Thread
      t[@scheduler.thread_key].should == true
      t[:rufus_scheduler_job].should == job
      t[:rufus_scheduler_time].should_not == nil
    end

    it 'does not return threads from other schedulers' do

      scheduler = Rufus::Scheduler.new

      job =
        @scheduler.schedule_in('0s') do
          sleep(1)
        end

      sleep 0.4

      scheduler.work_threads(:active).should == []

      scheduler.shutdown
    end
  end

  #describe '#min_work_threads' do
  #  it 'returns the min job thread count' do
  #    @scheduler.min_work_threads.should == 3
  #  end
  #end
  #describe '#min_work_threads=' do
  #  it 'sets the min job thread count' do
  #    @scheduler.min_work_threads = 1
  #    @scheduler.min_work_threads.should == 1
  #  end
  #end

  describe '#max_work_threads' do

    it 'returns the max job thread count' do

      @scheduler.max_work_threads.should == 28
    end
  end

  describe '#max_work_threads=' do

    it 'sets the max job thread count' do

      @scheduler.max_work_threads = 14

      @scheduler.max_work_threads.should == 14
    end
  end

  #describe '#kill_all_work_threads' do
  #
  #  it 'kills all the work threads' do
  #
  #    @scheduler.in '0s' do; sleep(5); end
  #    @scheduler.in '0s' do; sleep(5); end
  #    @scheduler.in '0s' do; sleep(5); end
  #
  #    sleep 0.5
  #
  #    @scheduler.work_threads.size.should == 3
  #
  #    @scheduler.send(:kill_all_work_threads)
  #
  #    sleep 0.5
  #
  #    @scheduler.work_threads.size.should == 0
  #  end
  #end

  describe '#running_jobs' do

    it 'returns [] when there are no running jobs' do

      @scheduler.running_jobs.should == []
    end

    it 'returns a list of running Job instances' do

      job =
        @scheduler.schedule_in('0s') do
          sleep(1)
        end

      sleep 0.4

      job.running?.should == true
      @scheduler.running_jobs.should == [ job ]
    end

    it 'does not return twice the same job' do

      job =
        @scheduler.schedule_every('0.3s') do
          sleep(5)
        end

      sleep 1.5

      job.running?.should == true
      @scheduler.running_jobs.should == [ job ]
    end
  end

  describe '#running_jobs(:tag/:tags => x)' do

    it 'returns a list of running jobs filtered by tag' do

      @scheduler.in '0.1s', :tag => 't0' do
        sleep 3
      end
      @scheduler.in '0.2s', :tag => 't1' do
        sleep 3
      end

      sleep 0.4

      @scheduler.running_jobs(:tag => 't0').map(&:original).should ==
        %w[ 0.1s ]
      @scheduler.running_jobs(:tag => 't1').map(&:original).should ==
        %w[ 0.2s ]
      @scheduler.running_jobs(:tags => %w[ t0 t1 ]).map(&:original).should ==
        []
    end
  end

  #--
  # management methods
  #++

  describe '#shutdown' do

    it 'blanks the uptime' do

      @scheduler.shutdown

      @scheduler.uptime.should == nil
    end

    it 'shuts the scheduler down' do

      @scheduler.shutdown

      sleep 0.100
      sleep 0.400 if RUBY_VERSION < '1.9.0'

      t = Thread.list.find { |t|
        t[:name] == "rufus_scheduler_#{@scheduler.object_id}"
      }

      t.should == nil
    end

    it 'has a #stop alias' do

      @scheduler.stop

      @scheduler.uptime.should == nil
    end

    #it 'has a #close alias'
  end

  describe '#shutdown(:wait)' do

    it 'shuts down and blocks until all the jobs ended their current runs' do

      counter = 0

      @scheduler.in '0s' do
        sleep 1
        counter = counter + 1
      end

      sleep 0.4

      @scheduler.shutdown(:wait)

      counter.should == 1
      @scheduler.uptime.should == nil
      @scheduler.running_jobs.should == []
      @scheduler.threads.should == []
    end
  end

  describe '#shutdown(:kill)' do

    it 'kills all the jobs and then shuts down' do

      counter = 0

      @scheduler.in '0s' do
        sleep 1
        counter = counter + 1
      end
      @scheduler.at Time.now + 0.3 do
        sleep 1
        counter = counter + 1
      end

      sleep 0.4

      @scheduler.shutdown(:kill)

      sleep 1.4

      counter.should == 0
      @scheduler.uptime.should == nil
      @scheduler.running_jobs.should == []
      @scheduler.threads.should == []
    end
  end

  describe '#pause' do

    it 'pauses the scheduler' do

      job = @scheduler.schedule_in '1s' do; end

      @scheduler.pause

      sleep(3)

      job.last_time.should == nil
    end
  end

  describe '#resume' do

    it 'works' do

      job = @scheduler.schedule_in '2s' do; end

      @scheduler.pause
      sleep(1)
      @scheduler.resume
      sleep(2)

      job.last_time.should_not == nil
    end
  end

  describe '#paused?' do

    it 'returns true if the scheduler is paused' do

      @scheduler.pause
      @scheduler.paused?.should == true
    end

    it 'returns false if the scheduler is not paused' do

      @scheduler.paused?.should == false

      @scheduler.pause
      @scheduler.resume

      @scheduler.paused?.should == false
    end
  end

  describe '#down?' do

    it 'returns true when the scheduler is down' do

      @scheduler.shutdown

      @scheduler.down?.should == true
    end

    it 'returns false when the scheduler is up' do

      @scheduler.down?.should == false
    end
  end

  #--
  # job methods
  #++

  describe '#jobs' do

    it 'is empty at the beginning' do

      @scheduler.jobs.should == []
    end

    it 'returns the list of scheduled jobs' do

      @scheduler.in '10d' do; end
      @scheduler.in '1w' do; end

      sleep(1)

      jobs = @scheduler.jobs

      jobs.collect { |j| j.original }.sort.should == %w[ 10d 1w ]
    end

    it 'returns all the jobs (even those pending reschedule)' do

      @scheduler.in '0s', :blocking => true do
        sleep 2
      end

      sleep 0.4

      @scheduler.jobs.size.should == 1
    end

    it 'does not return unscheduled jobs' do

      job =
        @scheduler.schedule_in '0s', :blocking => true do
          sleep 2
        end

      sleep 0.4

      job.unschedule

      @scheduler.jobs.size.should == 0
    end
  end

  describe '#jobs(:tag / :tags => x)' do

    it 'returns [] when there are no jobs with the corresponding tag' do

      @scheduler.jobs(:tag => 'nada').should == []
      @scheduler.jobs(:tags => %w[ nada hello ]).should == []
    end

    it 'returns the jobs with the corresponding tag' do

      @scheduler.in '10d', :tag => 't0' do; end
      @scheduler.every '2h', :tag => %w[ t0 t1 ] do; end
      @scheduler.every '3h' do; end

      @scheduler.jobs(:tags => 't0').map(&:original).sort.should ==
        %w[ 10d 2h ]
      @scheduler.jobs(:tags => 't1').map(&:original).sort.should ==
        %w[ 2h ]
      @scheduler.jobs(:tags => [ 't1', 't0' ]).map(&:original).sort.should ==
        %w[ 2h ]
    end
  end

  describe '#every_jobs' do

    it 'returns EveryJob instances' do

      @scheduler.at '2030/12/12 12:10:00' do; end
      @scheduler.in '10d' do; end
      @scheduler.every '5m' do; end

      jobs = @scheduler.every_jobs

      jobs.collect { |j| j.original }.sort.should == %w[ 5m ]
    end
  end

  describe '#at_jobs' do

    it 'returns AtJob instances' do

      @scheduler.at '2030/12/12 12:10:00' do; end
      @scheduler.in '10d' do; end
      @scheduler.every '5m' do; end

      jobs = @scheduler.at_jobs

      jobs.collect { |j| j.original }.sort.should == [ '2030/12/12 12:10:00' ]
    end
  end

  describe '#in_jobs' do

    it 'returns InJob instances' do

      @scheduler.at '2030/12/12 12:10:00' do; end
      @scheduler.in '10d' do; end
      @scheduler.every '5m' do; end

      jobs = @scheduler.in_jobs

      jobs.collect { |j| j.original }.sort.should == %w[ 10d ]
    end
  end

  describe '#cron_jobs' do

    it 'returns CronJob instances' do

      @scheduler.at '2030/12/12 12:10:00' do; end
      @scheduler.in '10d' do; end
      @scheduler.every '5m' do; end
      @scheduler.cron '* * * * *' do; end

      jobs = @scheduler.cron_jobs

      jobs.collect { |j| j.original }.sort.should == [ '* * * * *' ]
    end
  end

  describe '#interval_jobs' do

    it 'returns IntervalJob instances' do

      @scheduler.at '2030/12/12 12:10:00' do; end
      @scheduler.in '10d' do; end
      @scheduler.every '5m' do; end
      @scheduler.cron '* * * * *' do; end
      @scheduler.interval '7m' do; end

      jobs = @scheduler.interval_jobs

      jobs.collect { |j| j.original }.sort.should == %w[ 7m ]
    end
  end

  #--
  # callbacks
  #++

  describe '#on_pre_trigger' do

    it 'is called right before a job triggers' do

      $out = []

      def @scheduler.on_pre_trigger(job)
        $out << "pre #{job.id}"
      end

      job_id =
        @scheduler.in '0.5s' do |job|
          $out << job.id
        end

      sleep 0.7

      $out.should == [ "pre #{job_id}", job_id ]
    end

    it 'accepts the job and the triggerTime as argument' do

      $tt = nil

      def @scheduler.on_pre_trigger(job, trigger_time)
        $tt = trigger_time
      end

      start = Time.now

      @scheduler.in '0.5s' do; end

      sleep 0.7

      $tt.class.should == Time
      $tt.should > start
      $tt.should < Time.now
    end

    context 'when it returns false' do

      it 'prevents the job from triggering' do

        $out = []

        def @scheduler.on_pre_trigger(job)
          $out << "pre #{job.id}"
          false
        end

        job_id =
          @scheduler.in '0.5s' do |job|
            $out << job.id
          end

        sleep 0.7

        $out.should == [ "pre #{job_id}" ]
      end
    end
  end

  describe '#on_post_trigger' do

    it 'is called right after a job triggers' do

      $out = []

      def @scheduler.on_post_trigger(job)
        $out << "post #{job.id}"
      end

      job_id =
        @scheduler.in '0.5s' do |job|
          $out << job.id
        end

      sleep 0.7

      $out.should == [ job_id, "post #{job_id}" ]
    end
  end

  #--
  # misc
  #++

  describe '.singleton / .s' do

    before(:each) do

      Rufus::Scheduler.class_eval { @singleton = nil } # ;-)
    end

    it 'returns a singleton instance of the scheduler' do

      s0 = Rufus::Scheduler.singleton
      s1 = Rufus::Scheduler.s

      s0.class.should == Rufus::Scheduler
      s1.object_id.should == s0.object_id
    end

    it 'accepts initialization parameters' do

      s = Rufus::Scheduler.singleton(:max_work_threads => 77)
      s = Rufus::Scheduler.singleton(:max_work_threads => 42)

      s.max_work_threads.should == 77
    end
  end
end

