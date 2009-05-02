#!/usr/bin/env ruby

#
# A test by http://twitter.com/kjw
#

require 'test/unit'
$LOAD_PATH << 'lib'
require 'rufus/sc/scheduler'

require 'rubygems'
require 'eventmachine'

class CronTest < Test::Unit::TestCase

#
# Stress test program for rufus-scheduler
#

SECONDS_FROM_NOW = 30
MODE = :cron
JOB_COUNT = 1000
JOB_IDS = (1..JOB_COUNT).to_a
NUM_RESCHEDULES = 20

def setup
  @trigger_queue = Queue.new
end

def test_stress_schedule_unschedule_plain_cron
  stress_schedule_unschedule(:cron, Rufus::Scheduler::PlainScheduler.start_new)
end

def test_stress_schedule_unschedule_plain_at
  stress_schedule_unschedule(:at, Rufus::Scheduler::PlainScheduler.start_new)
end

def test_stress_schedule_unschedule_plain_every
  stress_schedule_unschedule(:every, Rufus::Scheduler::PlainScheduler.start_new)
end

def test_stress_schedule_unschedule_em_cron
  stress_schedule_unschedule(:cron, Rufus::Scheduler::EmScheduler.start_new)
end

def test_stress_schedule_unschedule_em_at
  stress_schedule_unschedule(:at, Rufus::Scheduler::EmScheduler.start_new)
end

def test_stress_schedule_unschedule_em_every
  stress_schedule_unschedule(:every, Rufus::Scheduler::EmScheduler.start_new)
end

protected

def stress_schedule_unschedule(mode, scheduler)

  # Schedule all jobs, then unschedule and (re)schedule a number of times
  schedule_unschedule(scheduler, mode, NUM_RESCHEDULES)

  # give scheduler thread 10 seconds to process the schedule and unschedule requests
  # but don't wait for the jobs to trigger (which is in less than 30 seconds)
  sleep 10
  # print_scheduler_counts(scheduler, 10)

  # by now the scheduler should have processed everything, check
  assert(JOB_IDS.sort == scheduler.find_jobs.map{ |job| job.job_id }.sort)
  sleep SECONDS_FROM_NOW # wait for jobs to trigger
  assert(JOB_COUNT == @trigger_queue.size)
end

def schedule_unschedule(scheduler, mode, num_reschedules)
  schedule_jobs(scheduler, mode)
  1.upto(num_reschedules) do
    sleep 0.01 # cause schedule's to happen before unscheduling
    unschedule_jobs(scheduler)
    schedule_jobs(scheduler, mode)
  end
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

def schedule_jobs(scheduler, mode)
  trigger_proc = lambda { |params| @trigger_queue << params[:job_id] }
  JOB_IDS.each do |job_id|
    case mode
    when :at
      scheduler.at(Time.now + SECONDS_FROM_NOW, {:job_id => job_id}, &trigger_proc)
    when :every
      scheduler.every("#{SECONDS_FROM_NOW}s", {:job_id => job_id}, &trigger_proc)
    when :cron
      scheduler.cron("%d * * * * *" % ((Time.now.to_i%60) + SECONDS_FROM_NOW) % 60,
                     {:job_id => job_id}, &trigger_proc)
    end
  end
end

def unschedule_jobs(scheduler)
  JOB_IDS.each { |job_id| scheduler.unschedule(job_id) }
end

end

