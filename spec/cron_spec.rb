
#
# Specifying rufus-scheduler
#
# Sun Mar 22 19:59:12 JST 2009
#

require File.dirname(__FILE__) + '/spec_base'


describe "#{SCHEDULER_CLASS}#cron" do

  before do
    @s = start_scheduler
  end
  after do
    stop_scheduler(@s)
  end

  it 'should have job ids with the class name in it' do

    j0 = @s.cron('7 10-12 * * * *') {}
    j0.job_id.should.match(/Rufus::Scheduler::CronJob/)
  end

  it 'should cron every second' do

    seconds = []

    job = @s.cron '* * * * * *'  do |job|
      seconds << job.last.sec
    end
    sleep 4.990

    job.unschedule

    seconds.uniq.size.should.equal(seconds.size)
  end

  it 'should unschedule' do

    second = nil

    job = @s.cron '* * * * * *'  do |job|
      second = job.last.sec
    end

    second.should.be.nil

    sleep 2

    second.should.not.be.nil

    job.unschedule

    after = second

    sleep 2

    second.should.equal(after)
  end

  it 'should keep track of cron jobs' do

    j0 = @s.cron '7 10-12 * * * *' do
    end
    j1 = @s.cron '7 10-12 * * * *' do
    end

    @s.cron_jobs.keys.sort.should.equal([ j0.job_id, j1.job_id ].sort)
  end

  it 'should accept tags for jobs' do

    job = @s.cron '* * * * * *', :tags => 'spec' do
    end

    wait_next_tick

    @s.find_by_tag('spec').size.should.equal(1)
    @s.find_by_tag('spec').first.job_id.should.equal(job.job_id)
  end

  it 'should accept job.unschedule within the job' do

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

    @s.jobs.size.should.equal(0)
    stack.should.equal(%w[ ok ok ok done ])
  end

end

describe Rufus::Scheduler::CronJob do

  before do
    @s = start_scheduler
  end
  after do
    stop_scheduler(@s)
  end

  it 'should respond to #next_time' do

    job = @s.cron '* * * * *' do
    end

    (job.next_time.to_i - Time.now.to_i).should.satisfy { |v| v < 60 }
  end
end

