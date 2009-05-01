#!/usr/bin/env ruby

#
# A test by http://twitter.com/kjw
#

#require 'rubygems'
#require 'rufus/scheduler'

#$:.unshift('../../rufus/rufus-scheduler/lib/')
#require 'rufus/scheduler'

$:.unshift('lib/')
require 'rufus/scheduler/em'


#
# Test program for rufus-scheduler
#
# Run like this:
# test.rb at
# test.rb every
# test.rb cron
#

SECONDS_FROM_NOW = 30
#MODE = ([:at, :every, :cron].include?(ARGV[0].to_sym) ? ARGV[0].to_sym : :cron)
MODE = (ARGV[0] || 'cron').to_sym
JOB_COUNT = 1000
JOB_IDS = (1..JOB_COUNT).to_a
NUM_RESCHEDULES = 10

case MODE
when :at
  AT_TRIGGER = Time.now + SECONDS_FROM_NOW # 30 seconds from now
when :every
  EVERY_TRIGGER = "#{SECONDS_FROM_NOW}s" # after 30 seconds
when :cron
  CRON_TRIGGER = ((Time.now.to_i%60) + SECONDS_FROM_NOW) % 60 # 30 seconds from now
end
puts "#{MODE.to_s}: #{SECONDS_FROM_NOW}s from now"

@trigger_queue = Queue.new

def schedule_jobs(scheduler)
  trigger_proc = lambda { |params|
    # print "#{params[:job_id]}, "
    @trigger_queue << params[:job_id]
  }
  JOB_IDS.each do |job_id|
    case MODE
    when :at
      scheduler.at(AT_TRIGGER, {:job_id => job_id}, &trigger_proc)
    when :every
      scheduler.every(EVERY_TRIGGER, {:job_id => job_id}, &trigger_proc)
    when :cron
      scheduler.cron("%d * * * * *" % CRON_TRIGGER, {:job_id => job_id}, &trigger_proc)
    end
  end
end

def unschedule_jobs(scheduler)
  JOB_IDS.each { |job_id|
    #p [ :unschedule, job_id ]
    scheduler.unschedule(job_id)
  }
end

sc = defined?(Rufus::Scem) ? Rufus::Scem::PlainScheduler : Rufus::Scheduler

scheduler = sc.start_new

# Schedule all jobs, then unschedule and (re)schedule a number of times

schedule_jobs(scheduler)

1.upto(NUM_RESCHEDULES) do

  unschedule_jobs(scheduler)
  schedule_jobs(scheduler)
end

# give scheduler thread 10 seconds to process the schedule and unschedule requests
# but don't wait for the jobs to trigger (which is in less than 60 seconds)
1.upto(10) do
  puts "all:%d at:%d cron:%d every:%d pending:%d" % [
    scheduler.all_jobs.size,
    scheduler.at_job_count,
    scheduler.cron_job_count,
    scheduler.every_job_count,
    scheduler.pending_job_count]
  sleep 1
end

#puts "=" * 80
#jobs = scheduler.find_jobs.map { |job| job.job_id }.sort
#p JOB_IDS.size
#p jobs.size
#p JOB_IDS - jobs
#p jobs - JOB_IDS
#puts "=" * 80

# by now the scheduler should have processed everything, check
test_result = nil
if JOB_IDS.sort == scheduler.find_jobs.map{ |job| job.job_id }.sort
  puts test_result = "PASS"
else
  puts test_result = "FAIL: find_jobs does not return all jobs"
end

wait = 30
puts "Waiting #{wait} seconds for jobs to trigger"
sleep wait # wait for jobs to trigger
puts "\nTriggered #{@trigger_queue.size} jobs, should be (#{JOB_COUNT})"
puts test_result

