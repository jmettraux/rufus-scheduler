
#
# Specifying rufus-scheduler
#
# Sat Mar 21 17:36:36 JST 2009
#

require File.dirname(__FILE__) + '/spec_base'


describe "#{SCHEDULER_CLASS}#in" do

  before do
    @s = start_scheduler
  end
  after do
    stop_scheduler(@s)
  end

  it 'should have job ids with the class name in it' do

    j0 = @s.in(1) {}
    j0.job_id.should.match(/Rufus::Scheduler::InJob/)
  end

  it 'should track scheduled in jobs' do

    @s.in(1) {}

    wait_next_tick
    @s.jobs.size.should.equal(1)

    sleep 1.5

    @s.jobs.size.should.equal(0)
  end

  it 'should schedule in 1' do

    var = nil

    @s.in 1 do
      var = true
    end

    var.should.be.nil
    sleep 1.5

    var.should.be.true
  end

  it 'should schedule in 1.0' do

    var = nil

    @s.in 1.0 do
      var = true
    end

    var.should.be.nil
    sleep 1.5

    var.should.be.true
  end

  it 'should schedule in 1s' do

    var = nil

    @s.in '1s' do
      var = true
    end

    var.should.be.nil
    sleep 1.5

    var.should.be.true
  end

  it 'should trigger [almost] immediately jobs in the past' do

    var = nil

    @s.in -2 do
      var = true
    end

    #wait_next_tick
    sleep 0.550

    var.should.be.true
    @s.jobs.should.be.empty
  end

  it 'should not trigger jobs in the past when :discard_past => true' do

    var = nil

    @s.in -2, :discard_past => true do
      var = true
    end

    var.should.be.nil
    @s.jobs.should.be.empty
  end

  it 'should unschedule job' do

    job = @s.in '2d' do
    end

    wait_next_tick

    @s.jobs.size.should.equal(1)

    @s.unschedule(job.job_id)

    @s.jobs.size.should.equal(0)
  end

  it 'should accept tags for jobs' do

    job = @s.in '2d', :tags => 'spec' do
    end

    wait_next_tick

    @s.find_by_tag('spec').size.should.equal(1)
    @s.find_by_tag('spec').first.job_id.should.equal(job.job_id)
  end

end

describe Rufus::Scheduler::InJob do

  before do
    @s = start_scheduler
  end
  after do
    stop_scheduler(@s)
  end

  it 'should unschedule itself' do

    job = @s.in '2d' do
    end

    wait_next_tick

    job.unschedule

    @s.jobs.size.should.equal(0)
  end

  it 'should respond to #next_time' do

    t = Time.now + 3 * 3600

    job = @s.in '3h' do
    end

    job.next_time.to_i.should.equal(t.to_i)
  end
end

