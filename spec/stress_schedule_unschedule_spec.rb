
#
# a spec by Klaas Jan Wierenga
#

require 'spec_base'



JOB_COUNT = 500 # 1000
JOB_IDS = (1..JOB_COUNT).to_a
NUM_RESCHEDULES = 5 # 10
TRIGGER_DELAY = 4 # 15


describe SCHEDULER_CLASS do

  # helper methods

  # Wait for a variable to become a certain value.
  # This method returns a block which loops waiting for the passed in
  # block paramter to have value 'target'.
  #
  def eventually(timeout = TRIGGER_DELAY * 2, precision = 1)
    lambda { |target|
      value = nil
      (timeout/precision).to_i.times do
        value = yield # read variable once
        # puts "got #{value}, expected #{target}"
        break if target == value
        sleep precision
      end
      target == value
    }
  end

  def benchmark
    now = Time.now
    yield
    benchmark = Time.now - now
    print " (scheduling took #{benchmark}s)"
    if benchmark > TRIGGER_DELAY
      puts "\nTEST RESULT INVALID/UNRELIABLE"
      puts "Scheduling took longer than TRIGGER_DELAY (#{TRIGGER_DELAY}s)."
      puts "Increase TRIGGER_DELAY to a value larger than largest scheduling time."
    end
  end

  def schedule_unschedule_same_ids_spec(mode)
    scheduler = SCHEDULER_CLASS.start_new
    benchmark { schedule_unschedule(scheduler, mode, NUM_RESCHEDULES) }
    JOB_COUNT.should satisfy &eventually { scheduler.all_jobs.size }
    JOB_IDS.sort.should == scheduler.find_jobs.map{ |job| job.job_id }.sort
    JOB_COUNT.should satisfy &eventually { @trigger_queue.size }
    @trigger_queue.size.should == JOB_COUNT
    scheduler.stop
  end

  def schedule_unschedule_unique_ids_spec(mode)
    scheduler = SCHEDULER_CLASS.start_new
    job_ids = []
    benchmark { job_ids = schedule_unschedule(scheduler, mode, NUM_RESCHEDULES, true) }
    JOB_COUNT.should satisfy &eventually { scheduler.all_jobs.size }
    job_ids.sort.should == scheduler.find_jobs.map{ |job| job.job_id }.sort
    JOB_COUNT.should satisfy &eventually { @trigger_queue.size }
    @trigger_queue.size.should == JOB_COUNT
    scheduler.stop
  end

  def scheduler_counts(scheduler)
    "all:%d at:%d cron:%d every:%d pending:%d" % [
      scheduler.all_jobs.size,
      scheduler.at_job_count,
      scheduler.cron_job_count,
      scheduler.every_job_count,
      scheduler.pending_job_count ]
  end

  def schedule_unschedule(scheduler, mode, num_reschedules, generate_ids=false)
    job_ids = schedule_jobs(scheduler, mode, generate_ids)
    1.upto(num_reschedules) do
      unschedule_jobs(scheduler, job_ids)
      job_ids = schedule_jobs(scheduler, mode, generate_ids)
    end
    job_ids
  end

  def schedule_jobs(scheduler, mode, generate_ids=false)
    job_ids = []
    JOB_IDS.each do |job_id|
      case mode
      when :cron
        job_ids << scheduler.cron(
          "%d * * * * *" % @cron_trigger,
          { :job_id => (generate_ids ? nil : job_id) },
          &@trigger_proc
        ).job_id
      when :at
        job_ids << scheduler.at(
          @at_trigger,
          { :job_id => (generate_ids ? nil : job_id) },
          &@trigger_proc
        ).job_id
      when :every
        job_ids << scheduler.every(
          @every_trigger,
          { :job_id => (generate_ids ? nil : job_id) },
          &@trigger_proc
        ).job_id
      else
        raise ArgumentError
      end
    end
    job_ids
  end

  def unschedule_jobs(scheduler, job_ids)
    job_ids.each { |job_id| scheduler.unschedule(job_id) }
  end

  # the actual tests

  before(:each) do
    @trigger_queue = Queue.new
    @cron_trigger = ((Time.now.to_i%60) + TRIGGER_DELAY) % 60 # 30 seconds from now
    @at_trigger = Time.now + TRIGGER_DELAY
    @every_trigger = "#{TRIGGER_DELAY}s"
    @trigger_proc = lambda { |job| @trigger_queue << job.job_id }
  end

  after(:each) do
    @trigger_queue = nil
  end

  it "sustains frequent schedule/unschedule 'cron' jobs with same ids" do
    schedule_unschedule_same_ids_spec(:cron)
  end

  it "sustains frequent schedule/unschedule 'at' jobs with same ids" do
    schedule_unschedule_same_ids_spec(:at)
  end

  it "sustains frequent schedule/unschedule 'every' jobs same ids" do
    schedule_unschedule_same_ids_spec(:every)
  end

  it "sustains frequent schedule/unschedule 'cron' jobs with unique ids" do
    schedule_unschedule_unique_ids_spec(:cron)
  end

  it "sustains frequent schedule/unschedule 'at' jobs with unique ids" do
    schedule_unschedule_unique_ids_spec(:at)
  end

  it "sustains frequent schedule/unschedule 'every' jobs unique ids" do
    schedule_unschedule_unique_ids_spec(:every)
  end
end

