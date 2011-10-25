
#
# Specifying rufus-scheduler
#
# Sun May  3 15:44:28 JST 2009
#

require 'spec_base'


describe "#{SCHEDULER_CLASS} timeouts" do

  before(:each) do
    @s = start_scheduler
  end
  after(:each) do
    stop_scheduler(@s)
  end

  it 'refuses to schedule a job with :timeout and :blocking' do

    lambda {
      @s.in '1s', :timeout => '3s', :blocking => true do
      end
    }.should raise_error(ArgumentError)
  end

  it 'schedules a dedicated job for the timeout' do

    @s.in '1s', :timeout => '3s' do
      sleep 5
    end

    @s.jobs.size.should == 1

    # the timeout job is left

    sleep 2
    @s.jobs.size.should == 1
    @s.find_by_tag('timeout').size.should == 1
  end

  it 'times out' do

    var = nil
    timedout = false

    @s.in '1s', :timeout => '1s' do
      begin
        sleep 2
        var = true
      rescue Rufus::Scheduler::TimeOutError => e
        timedout = true
      end
    end

    sleep 4

    var.should == nil
    @s.jobs.size.should == 0
    timedout.should == true
  end

  it 'dies silently if job finished before timeout' do

    var = nil
    timedout = false

    @s.in '1s', :timeout => '1s' do
      begin
        var = true
      rescue Rufus::Scheduler::TimeOutError => e
        timedout = true
      end
    end

    sleep 3

    var.should == true
    @s.jobs.size.should == 0
    timedout.should == false
  end

  it 'does not timeout other jobs (in case of every)' do

    timeouts = []

    @s.every '1s', :timeout => '1s500' do
      start = Time.now
      begin
        sleep 2.0
      rescue Rufus::Scheduler::TimeOutError => e
        timeouts << (Time.now - start)
      end
    end

    sleep 5.5

    timeouts.size.should == 3
    timeouts.each { |to| to.should be_within(0.5).of(1.5) }
  end

  it 'points to their "parent" job' do

    @s.in '1s', :timeout => '3s', :job_id => 'nada' do
      sleep 4
    end

    sleep 2

    @s.jobs.values.first.parent.job_id.should == 'nada'
  end

  it 'does not survive their job' do

    @s.in '1s', :timeout => '3s' do
      sleep 0.100
    end

    sleep 2

    @s.jobs.size.should == 0
  end
end

