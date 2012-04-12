
#
# Specifying rufus-scheduler
#
# Sun Mar 22 19:59:12 JST 2009
#

require 'spec_base'


describe "#{SCHEDULER_CLASS}#cron" do

  before(:each) do
    @s = start_scheduler
  end
  after(:each) do
    stop_scheduler(@s)
  end

  it 'has job ids with the class name in it' do

    j0 = @s.cron('7 10-12 * * * *') {}
    j0.job_id.should match(/Rufus::Scheduler::CronJob/)
  end

  it 'crons every second' do

    seconds = []

    job = @s.cron '* * * * * *'  do |job|
      seconds << job.last.sec
    end
    sleep 4.990

    job.unschedule

    seconds.uniq.size.should == seconds.size
  end

  it 'unschedules (self)' do

    second = nil

    job = @s.cron '* * * * * *'  do |job|
      second = job.last.sec
    end

    second.should == nil

    sleep 2

    second.should_not == nil

    job.unschedule

    after = second

    sleep 2

    second.should == after
  end

  it 'unschedules (job)' do

    second = nil

    job = @s.cron '* * * * * *'  do |job|
      second = job.last.sec
    end

    second.should == nil

    sleep 2

    second.should_not == nil

    @s.unschedule(job)

    after = second

    sleep 2

    second.should == after
  end

  it 'keeps track of cron jobs' do

    j0 = @s.cron '7 10-12 * * * *' do
    end
    j1 = @s.cron '7 10-12 * * * *' do
    end

    @s.cron_jobs.keys.sort.should == [ j0.job_id, j1.job_id ].sort
  end

  it 'accepts tags for jobs' do

    job = @s.cron '* * * * * *', :tags => 'spec' do
    end

    wait_next_tick

    @s.find_by_tag('spec').size.should == 1
    @s.find_by_tag('spec').first.job_id.should == job.job_id
  end

  it 'accepts job.unschedule within the job' do

    stack = []

    @s.cron '* * * * * *' do |job|
      if stack.size > 2
        stack << 'done'
        job.unschedule
      else
        stack << 'ok'
      end
    end

    sleep 4

    @s.jobs.size.should == 0
    stack.should == %w[ ok ok ok done ]
  end

  it 'raises on unknown options' do

    lambda {
      @s.cron '* * * * *', :pool => :party do
      end
    }.should raise_error(ArgumentError)
  end
end

