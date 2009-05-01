require 'rubygems'
require 'spec/autorun'

$LOAD_PATH << 'lib/'
require 'rufus/scheduler'

describe Rufus::Scheduler do

  JOB_COUNT = 1000
  JOB_IDS = (1..JOB_COUNT).to_a
  NUM_RESCHEDULES = 20
  SECONDS_FROM_NOW = 30

  before(:each) do
    @trigger_queue = Queue.new
    @cron_trigger = ((Time.now.to_i%60) + SECONDS_FROM_NOW) % 60 # 30 seconds from now
    @at_trigger = Time.now + SECONDS_FROM_NOW
    @every_trigger = "#{SECONDS_FROM_NOW}s"
    @trigger_proc = lambda { |params| @trigger_queue << params[:job_id] }
    @scheduler = Rufus::Scheduler.start_new
  end

  after(:each) do
    @scheduler.stop; @scheduler.join
    @scheduler = nil
  end

  it "should immediately trigger an at event in the past" do
    @scheduler.at(Time.now - 10, {}, &@trigger_proc)
    sleep 1
    @trigger_queue.size.should be(1)
  end

  it "should allow frequent schedule/unschedule 'cron' jobs with same ids" do
    schedule_unschedule(@scheduler, :cron, NUM_RESCHEDULES)
    JOB_IDS.sort.should eql(@scheduler.find_jobs.map{ |job| job.job_id }.sort)
    sleep SECONDS_FROM_NOW # wait for jobs to trigger
    @trigger_queue.size.should be(JOB_COUNT)
  end

  it "should allow frequent schedule/unschedule 'at' jobs with same ids" do
    schedule_unschedule(@scheduler, :at, NUM_RESCHEDULES)
    JOB_IDS.sort.should eql(@scheduler.find_jobs.map{ |job| job.job_id }.sort)
    sleep SECONDS_FROM_NOW # wait for jobs to trigger
    @trigger_queue.size.should be(JOB_COUNT)
  end

  it "should allow frequent schedule/unschedule 'every' jobs same ids" do
    schedule_unschedule(@scheduler, :every, NUM_RESCHEDULES)
    JOB_IDS.sort.should eql(@scheduler.find_jobs.map{ |job| job.job_id }.sort)
    sleep SECONDS_FROM_NOW # wait for jobs to trigger
    @trigger_queue.size.should be(JOB_COUNT)
  end

  it "should allow frequent schedule/unschedule 'cron' jobs with unique ids" do
    job_ids = schedule_unschedule(@scheduler, :cron, NUM_RESCHEDULES)
    job_ids.sort.should eql(@scheduler.find_jobs.map{ |job| job.job_id }.sort)
    sleep SECONDS_FROM_NOW # wait for jobs to trigger
    @trigger_queue.size.should be(JOB_COUNT)
  end

  it "should allow frequent schedule/unschedule 'at' jobs with unique ids" do
    job_ids = schedule_unschedule(@scheduler, :at, NUM_RESCHEDULES, true)
    job_ids.sort.should eql(@scheduler.find_jobs.map{ |job| job.job_id }.sort)
    sleep SECONDS_FROM_NOW # wait for jobs to trigger
    @trigger_queue.size.should be(JOB_COUNT)
  end

  it "should allow frequent schedule/unschedule 'every' jobs unique ids" do
    job_ids = schedule_unschedule(@scheduler, :every, NUM_RESCHEDULES, true)
    job_ids.sort.should eql(@scheduler.find_jobs.map{ |job| job.job_id }.sort)
    sleep SECONDS_FROM_NOW # wait for jobs to trigger
    @trigger_queue.size.should be(JOB_COUNT)
  end

  protected

  # helper methods

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
                                  &@trigger_proc)
      when :at
        job_ids << scheduler.at(@at_trigger,
                                { :job_id => (generate_ids ? nil : job_id) },
                                &@trigger_proc)
      when :every
        job_ids << scheduler.every(@every_trigger,
                                   { :job_id => (generate_ids ? nil : job_id) },
                                   &@trigger_proc)
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

