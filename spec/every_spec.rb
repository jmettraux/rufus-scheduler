
#
# Specifying rufus-scheduler
#
# Sun Mar 22 12:26:07 JST 2009
#

require File.dirname(__FILE__) + '/spec_base'


describe "#{SCHEDULER_CLASS}#every" do

  before do
    @s = start_scheduler
  end
  after do
    stop_scheduler(@s)
  end

  it 'should have job ids with the class name in it' do

    j0 = @s.every(1) {}
    j0.job_id.should.match(/Rufus::Scheduler::EveryJob/)
  end

  it 'should compute frequency' do

    job = @s.every '2h1m' do
    end
    job.frequency.should.equal(7260)
  end

  it 'should schedule every 1s' do

    var = 0

    job = @s.every '1s' do
      var += 1
    end

    sleep 3.7

    var.should.equal(3)
  end

  it 'should be punctilious' do

    hits = []

    job = @s.every '1s' do
      hits << Time.now.to_f
    end

    sleep 9.9

    hh = nil
    deltas = []
    hits.each { |h| f = h; deltas << (f - hh) if hh; hh = f }

    #puts; p deltas
    deltas.max.should.satisfy { |d| d < 1.200 }
  end

  it 'should unschedule' do

    var = 0

    job = @s.every '1s' do
      var += 1
    end

    sleep 2.7

    @s.unschedule(job.job_id)

    var.should.equal(2)

    sleep 1.7

    var.should.equal(2)
  end

  it 'should accept tags for jobs' do

    job = @s.every '1s', :tags => 'spec' do
    end

    wait_next_tick

    @s.find_by_tag('spec').size.should.equal(1)
    @s.find_by_tag('spec').first.job_id.should.equal(job.job_id)
  end

  it 'should honour :first_at' do

    counter = 0

    job = @s.every '1s', :first_at => Time.now + 2 do
      counter += 1
    end

    sleep 1
    counter.should.equal(0)

    sleep 2.5
    counter.should.equal(2)
  end

  it 'should honour :first_in' do

    counter = 0

    job = @s.every '1s', :first_in => 2 do
      counter += 1
    end

    sleep 1
    counter.should.equal(0)

    sleep 2.5
    counter.should.equal(2)
  end

  it 'should honour :dont_reschedule' do

    stack = []

    @s.every 0.400 do |params|
      if stack.size > 3
        stack << 'done'
        params[:dont_reschedule] = true
      else
        stack << 'ok'
      end
    end

    sleep 4

    @s.jobs.size.should.equal(0)
    stack.should.equal(%w[ ok ok ok ok done ])
  end

end

