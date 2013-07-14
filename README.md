
# rufus-scheduler

[![Build Status](https://secure.travis-ci.org/jmettraux/rufus-scheduler.png)](http://travis-ci.org/jmettraux/rufus-scheduler)

Job scheduler for Ruby (at, cron, in and every jobs).

```
require 'rufus-scheduler'

scheduler = Rufus::Scheduler.new

# ...

scheduler.in '10d' do
  # do something in 10 days
end

scheduler.at '2030/12/12 23:30:00' do
  # do something at a given point in time
end

scheduler.every '3h' do
  # do something every 3 hours
end

scheduler.cron '5 0 * * *' do
  # do something every day, five minutes after midnight
  # (see "man 5 crontab" in your terminal)
end
```


## note about the 3.0 line

It's a complete rewrite of rufus-scheduler.

There is no EventMachine-based scheduler anymore.


## Notables changes:

* As said, no more EventMachine-based scheduler
* ```scheduler.every('100') {``` will schedule every 100 seconds (previously, it would have been 0.1s). This aligns rufus-scheduler on Ruby's ```sleep(100)```
* The scheduler isn't catching the whole of Exception anymore, only StandardException
* Rufus::Scheduler::TimeOutError renamed to Rufus::Scheduler::TimeoutError


## scheduling

TODO: in/at/cron/every


## pause and resume the scheduler

The scheduler can be paused via the #pause and #resume methods. One can determine if the scheduler is currently paused by calling #paused?.

While paused, the scheduler still accepts schedules, but no schedule will get triggered as long as #resume isn't called.

TODO: :discard_the_past => true?


## job options

### :blocking => true

By default, jobs are triggered in their own, new thread. When :blocking => true, the job is triggered in the scheduler thread (a new thread is not created). Yes, while the job triggers, the scheduler is not scheduling.

### :overlap => false

Since, by default, jobs are triggered in their own new thread, job instances might overlap. For example, a job that takes 10 minutes and is scheduled every 7 minutes will have overlaps.

To prevent overlap, one can set :overlap => false. Such a job will not trigger if one of its instance is already running.

### :mutex => mutex_instance / mutex_name / array of mutexes

When a job with a mutex triggers, the job's block is executed with the mutex around it, preventing other jobs with the same mutex to enter (it makes the other jobs wait until it exits the mutex).

This is different from :overlap => false, which is, first, limited to instances of the same job, and, second, doesn't make the incoming job instance block/wait but give up.

:mutex accepts a mutex instance or a mutex name (String). It also accept an array of mutex names / mutex instances. It allows for complex relations between jobs.

Array of mutexes: original idea and implementation by [Rainux Luo](https://github.com/rainux)

### :timeout => duration or point in time

It's OK to specify a timeout when scheduling some work. After the time specified, it gets interrupted via a Rufus::Scheduler::TimeoutError.

```ruby
  scheduler.in '10d', :timeout => '1d' do
    begin
      # ... do something
    rescue Rufus::Scheduler::TimeoutError
      # ... that something got interrupted after 1 day
    end
  end
```

The :timeout option accepts either a duration (like "1d" or "2w3d") or a point in time (like "2013/12/12 12:00").


## Job methods

When calling a schedule method, the id (String) of the job is returned. Longer schedule methods return Job instances directly. Calling the shorter schedule methods with the :job => true also return Job instances instead of Job ids (Strings).

```ruby
  require 'rufus-scheduler'

  scheduler = Rufus::Scheduler.new

  job_id =
    scheduler.in '10d' do
      # ...
    end

  job =
    scheduler.schedule_in '1w' do
      # ...
    end

  job =
    scheduler.in '1w', :job => true do
      # ...
    end
```

Those Job instances have a few interesting methods / properties:

### id, job_id
### opts
### original
### scheduled_at
### last_time
### unschedule
### threads, thread_values
### running?

## AtJob and InJob methods
### time

## EveryJob methods
### frequency
### next_time

## CronJob methods


## looking up jobs

### Scheduler#job(job_id)

The scheduler #job(job_id) method can be used to lookup Job instances.

```ruby
  require 'rufus-scheduler'

  scheduler = Rufus::Scheduler.new

  job_id =
    scheduler.in '10d' do
      # ...
    end

  # later on...

  job = scheduler.job(job_id)
```

### Scheduler #jobs #at_jobs #in_jobs #every_jobs and #cron_jobs

Are methods for looking up lists of scheduled Job instances.

Here is an example:

```ruby
  #
  # let's unschedule all the at jobs

  scheduler.at_jobs.each(&:unschedule)
```

### Scheduler#running_jobs

Returns the list of Job instance that have currently running instances.

Whereas other "_jobs" method scan the scheduled job list, this method scans the thread list to find the job. It thus comprises jobs that are running but are not scheduled anymore (that happens for at and in jobs).


## misc Scheduler methods

### Scheduler#terminate_all_jobs

Unschedules all the jobs, then block until all the jobs that were running terminate.

### Scheduler#shutdown

Shuts down the scheduler, ceases any scheduler/triggering activity.

### Scheduler#join

Let's the current thread join the scheduling thread in rufus-scheduler. The thread comes back when the scheduler gets shut down.


## parsing cronlines and time strings

TODO


## license

MIT, see LICENSE.txt

