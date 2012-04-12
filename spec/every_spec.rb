
#
# Specifying rufus-scheduler
#
# Sun Mar 22 12:26:07 JST 2009
#

require 'spec_base'


describe "#{SCHEDULER_CLASS}#every" do

  before(:each) do
    @s = start_scheduler
  end
  after(:each) do
    stop_scheduler(@s)
  end

  it 'has job ids with the class name in it' do

    j0 = @s.every(1) {}
    j0.job_id.should match(/Rufus::Scheduler::EveryJob/)
  end

  it 'computes frequency' do

    job = @s.every '2h1m' do
    end
    job.frequency.should == 7260
  end

  it 'schedules every 1s' do

    var = 0

    job = @s.every '1s' do
      var += 1
    end

    sleep 3.7

    var.should == 3
  end

  it 'is punctilious' do

    hits = []

    job = @s.every '1s' do
      hits << Time.now.to_f
    end

    sleep 9.9

    hh = nil
    deltas = []
    hits.each { |h| f = h; deltas << (f - hh) if hh; hh = f }

    #puts; p deltas
    deltas.max.should satisfy { |d| d < 1.200 }
  end

  it 'unschedules' do

    var = 0

    job = @s.every '1s' do
      var += 1
    end

    sleep 2.7

    @s.unschedule(job.job_id)

    var.should == 2

    sleep 1.7

    var.should == 2
  end

  it 'accepts tags for jobs' do

    job = @s.every '1s', :tags => 'spec' do
    end

    wait_next_tick

    @s.find_by_tag('spec').size.should == 1
    @s.find_by_tag('spec').first.job_id.should == job.job_id
  end

  it 'honours :first_at' do

    counter = 0

    @s.every '1s', :first_at => Time.now + 2 do
      counter += 1
    end

    sleep 1
    counter.should == 0

    sleep 2.5
    counter.should == 2
  end

  it 'triggers for the missed schedules when :first_at is in the past' do

    counter = 0

    @s.every '1s', :first_at => Time.now - 2 do
      counter += 1
    end

    wait_next_tick
    counter.should == 3
  end

  it 'does not trigger for the missed schedules when :first_at is in the past and :discard_past => true' do

    counter = 0

    @s.every '1s', :first_at => Time.now - 2, :discard_past => true do
      counter += 1
    end

    wait_next_tick
    counter.should == 0
  end

  it 'honours :first_in' do

    counter = 0

    @s.every '1s', :first_in => 2 do
      counter += 1
    end

    sleep 1
    counter.should == 0

    sleep 2.5
    counter.should == 2
  end

  #it 'honours :dont_reschedule' do
  #  stack = []
  #  @s.every 0.400 do |job|
  #    if stack.size > 3
  #      stack << 'done'
  #      job.params[:dont_reschedule] = true
  #    else
  #      stack << 'ok'
  #    end
  #  end
  #  sleep 4
  #  @s.jobs.size.should.equal(0)
  #  stack.should.equal(%w[ ok ok ok ok done ])
  #end

  it 'accepts job.unschedule within the job' do

    stack = []

    @s.every 0.400 do |job|
      if stack.size > 3
        stack << 'done'
        job.unschedule
      else
        stack << 'ok'
      end
    end

    sleep 4

    @s.jobs.size.should == 0
    stack.should == %w[ ok ok ok ok done ]
  end

  it 'respects :blocking => true' do

    stack = []

    @s.every '1s', :blocking => true do |job|
      stack << 'ok'
      sleep 2
    end

    sleep 5

    stack.should == %w[ ok ok ]
  end

  it 'lists the "trigger threads"' do

    @s.every '1s' do
      sleep 10
    end
    sleep 5

    @s.trigger_threads.size.should == 4
  end

  it "doesn't allow overlapped execution if :allow_overlapping => false" do

    stack = []

    @s.every '1s', :allow_overlapping => false do |job|
      stack << 'ok'
      sleep 2
    end

    sleep 5

    stack.size.should == 2
  end

  it 'allows overlapped execution by default' do

    stack = []

    @s.every '1s' do |job|
      stack << 'ok'
      sleep 2
    end

    sleep 5

    stack.size.should == 4
  end

  it 'schedules anyway when exception and :allow_overlapping => false' do

    $exceptions = []

    def @s.handle_exception(job, exception)
      $exceptions << exception
    end

    @s.every '1s', :allow_overlapping => false do
      raise 'fail'
    end

    sleep 4

    $exceptions.size.should be > 1
  end

  it 'raises on unknown options' do

    lambda {
      @s.every '1s', :pool => :party do
      end
    }.should raise_error(ArgumentError)
  end
end

