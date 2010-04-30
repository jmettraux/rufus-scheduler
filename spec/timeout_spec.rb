
#
# Specifying rufus-scheduler
#
# Sun May  3 15:44:28 JST 2009
#

require File.dirname(__FILE__) + '/spec_base'


describe "#{SCHEDULER_CLASS} timeouts" do

  before do
    @s = start_scheduler
  end
  after do
    stop_scheduler(@s)
  end

  it 'should should refuse to schedule a job with :timeout and :blocking' do

    lambda {
      @s.in '1s', :timeout => '3s', :blocking => true do
      end
    }.should.raise(ArgumentError)
  end

  it 'should schedule a dedicated job for the timeout' do

    @s.in '1s', :timeout => '3s' do
      sleep 5
    end

    @s.jobs.size.should.equal(1)

    # the timeout job is left

    sleep 2
    @s.jobs.size.should.equal(1)
    @s.find_by_tag('timeout').size.should.equal(1)
  end

  it 'should time out' do

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

    var.should.be.nil
    @s.jobs.size.should.equal(0)
    timedout.should.be.true
  end

  it 'should die silently if job finished before timeout' do

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

    var.should.be.true
    @s.jobs.size.should.equal(0)
    timedout.should.be.false
  end

  it 'should not timeout other jobs (in case of every)' do

    timeouts = []

    @s.every '1s', :timeout => '1s500' do
      start = Time.now
      begin
        sleep 2.0
      rescue Rufus::Scheduler::TimeOutError => e
        timeouts << (Time.now - start)
      end
    end

    sleep 5

    timeouts.size.should.equal(3)
    timeouts.each { |to| (to * 10).to_i.should.equal(16) }
  end

  it 'should point to their "parent" job' do

    @s.in '1s', :timeout => '3s', :job_id => 'nada' do
      sleep 4
    end

    sleep 2

    @s.jobs.values.first.parent.job_id.should.equal('nada')
  end

  it 'should not survive their job' do

    @s.in '1s', :timeout => '3s' do
      sleep 0.100
    end

    sleep 2

    @s.jobs.size.should.equal(0)
  end
end

