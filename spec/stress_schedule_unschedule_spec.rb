
$LOAD_PATH << 'lib'
require 'rufus/sc/scheduler'

require 'rubygems'
require 'spec/autorun'
require 'eventmachine'

JOB_COUNT = 1000
JOB_IDS = (1..JOB_COUNT).to_a
NUM_RESCHEDULES = 20
SECONDS_FROM_NOW = 30

describe Rufus::Scheduler do
  
  before do #(:each) do
    @trigger_queue = Queue.new
    @cron_trigger = ((Time.now.to_i%60) + SECONDS_FROM_NOW) % 60 # 30 seconds from now
    @at_trigger = Time.now + SECONDS_FROM_NOW
    @every_trigger = "#{SECONDS_FROM_NOW}s"
    @trigger_proc = lambda { |params| @trigger_queue << params[:job_id] }
  end
  
  after do #(:each) do
    @trigger_queue = nil
  end
  
  it "should immediately trigger an at event in the past" do
    scheduler = Rufus::Scheduler::EmScheduler.start_new
    scheduler.at(Time.now - 10, {}, &@trigger_proc)
    sleep 1
    @trigger_queue.size.should be(1)
    scheduler.stop
  end

  it "(Plain) should allow frequent schedule/unschedule 'cron' jobs with same ids" do
    schedule_unschedule_same_ids_spec(:cron, Rufus::Scheduler::PlainScheduler.start_new)
  end
  
  it "(Plain) should allow frequent schedule/unschedule 'at' jobs with same ids" do
    schedule_unschedule_same_ids_spec(:at, Rufus::Scheduler::PlainScheduler.start_new)
  end
  
  it "(Plain) should allow frequent schedule/unschedule 'every' jobs same ids" do
    schedule_unschedule_same_ids_spec(:every,Rufus::Scheduler::PlainScheduler.start_new)
  end
  
  it "(Plain) should allow frequent schedule/unschedule 'cron' jobs with unique ids" do
    schedule_unschedule_unique_ids_spec(:cron, Rufus::Scheduler::PlainScheduler.start_new)
  end
  
  it "(Plain) should allow frequent schedule/unschedule 'at' jobs with unique ids" do
    schedule_unschedule_unique_ids_spec(:at, Rufus::Scheduler::PlainScheduler.start_new)
  end
  
  it "(Plain) should allow frequent schedule/unschedule 'every' jobs unique ids" do
    schedule_unschedule_unique_ids_spec(:every, Rufus::Scheduler::PlainScheduler.start_new)
  end
  
  it "(EM) should allow frequent schedule/unschedule 'cron' jobs with same ids" do
    schedule_unschedule_same_ids_spec(:cron, Rufus::Scheduler::EmScheduler.start_new)
  end

  it "(EM) should allow frequent schedule/unschedule 'at' jobs with same ids" do
    schedule_unschedule_same_ids_spec(:at, Rufus::Scheduler::EmScheduler.start_new)
  end
  
  it "(EM) should allow frequent schedule/unschedule 'every' jobs same ids" do
    schedule_unschedule_same_ids_spec(:every,Rufus::Scheduler::EmScheduler.start_new)
  end
  
  it "(EM) should allow frequent schedule/unschedule 'cron' jobs with unique ids" do
    schedule_unschedule_unique_ids_spec(:cron, Rufus::Scheduler::EmScheduler.start_new)
  end

  it "(EM) should allow frequent schedule/unschedule 'at' jobs with unique ids" do
    schedule_unschedule_unique_ids_spec(:at, Rufus::Scheduler::EmScheduler.start_new)
  end
  
  it "(EM) should allow frequent schedule/unschedule 'every' jobs unique ids" do
    schedule_unschedule_unique_ids_spec(:every, Rufus::Scheduler::EmScheduler.start_new)
  end

  # protected
  
  # helper methods
  
  def schedule_unschedule_same_ids_spec(mode, scheduler)
    schedule_unschedule(scheduler, mode, NUM_RESCHEDULES)
    JOB_IDS.sort.should eql(scheduler.find_jobs.map{ |job| job.job_id }.sort)
    sleep SECONDS_FROM_NOW # wait for jobs to trigger
    @trigger_queue.size.should be(JOB_COUNT)
    scheduler.stop
  end
  
  def schedule_unschedule_unique_ids_spec(mode, scheduler)
    job_ids = schedule_unschedule(scheduler, mode, NUM_RESCHEDULES, true)
    job_ids.sort.should eql(scheduler.find_jobs.map{ |job| job.job_id }.sort)
    sleep SECONDS_FROM_NOW # wait for jobs to trigger
    @trigger_queue.size.should be(JOB_COUNT)
    scheduler.stop
  end

  def schedule_unschedule(scheduler, mode, num_reschedules, generate_ids = false)
    job_ids = schedule_jobs(scheduler, mode, generate_ids)
    1.upto(num_reschedules) do
      sleep 0.01 # allows scheduler to pick up scheduled jobs
      unschedule_jobs(scheduler, job_ids)
      job_ids = schedule_jobs(scheduler, mode, generate_ids)
    end

    sleep 10 # allow scheduler to process schedule/unschedule requests
    # print_scheduler_counts(scheduler, 10)

    job_ids
  end

  def print_scheduler_counts(scheduler, seconds)
    1.upto(seconds) do
      puts "all:%d at:%d cron:%d every:%d pending:%d" % [
        scheduler.all_jobs.size,
        scheduler.at_job_count,
        scheduler.cron_job_count,
        scheduler.every_job_count,
        scheduler.pending_job_count]
      sleep 1
    end
  end

  def schedule_jobs(scheduler, mode, generate_ids = false)
    job_ids = []
    JOB_IDS.each do |job_id|
      case mode
      when :cron
        job_ids << scheduler.cron("%d * * * * *" % @cron_trigger,
                                  { :job_id => (generate_ids ? nil : job_id) },
                                  &@trigger_proc).job_id
      when :at
        job_ids << scheduler.at(@at_trigger,
                                { :job_id => (generate_ids ? nil : job_id) },
                                &@trigger_proc).job_id
      when :every
        job_ids << scheduler.every(@every_trigger,
                                   { :job_id => (generate_ids ? nil : job_id) },
                                   &@trigger_proc).job_id
      else
        raise ArgumentError
      end
    end
    job_ids
  end

  def unschedule_jobs(scheduler, job_ids)
    job_ids.each { |job_id| scheduler.unschedule(job_id) }
  end
  
end
  