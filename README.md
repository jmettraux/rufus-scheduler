
# rufus-scheduler

[![Build Status](https://secure.travis-ci.org/jmettraux/rufus-scheduler.png)](http://travis-ci.org/jmettraux/rufus-scheduler)

Job scheduler for Ruby (at, cron, in and every jobs).

**Warning**: this is the README of the 3.0 line of rufus-scheduler. It got promoted to master branch on 2013/07/15. Head to the [2.0 line's README](https://github.com/jmettraux/rufus-scheduler/blob/two/README.rdoc) if necessary (if your rufus-scheduler version is 2.0.x).

(When the 3.0 gem is released, this warning will get removed).

Quickstart:
```
require 'rufus-scheduler'

scheduler = Rufus::Scheduler.new

scheduler.in '3s' do
  puts 'Hello... Rufus'
end

scheduler.join
  # let the current thread join the scheduler thread
```

Various forms of scheduling are supported:
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

# ...
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

### schedule blocks arguments (job, time)

A schedule block may be given 0, 1 or 2 arguments.

The first argument is "job", it's simple the Job instance involved. It might be useful if the job is to be unscheduled for some reason.

```ruby
scheduler.every '10m' do |job|

  status = determine_pie_status

  if status == 'burnt' || status == 'cooked'
    stop_oven
    takeout_pie
    job.unschedule
  end
end
```

The second argument is "time", it's the time when the job got cleared for triggering (not Time.now).

Note that time is the time when the job got cleared for triggering. If there are mutexes involved, now = mutex_wait_time + time...

### scheduling not just blocks

It's OK to pass any object, as long as it respond to #call(), when scheduling:

```ruby
class Handler
  def self.call(job, time)
    p "- Handler called for #{job.id} at #{time}"
  end
end

scheduler.in '10d', Handler

# or

class OtherHandler
  def initialize(name)
    @name = name
  end
  def call(job, time)
    p "* #{time} - Handler #{name.inspect} called for #{job.id}"
  end
end

oh = OtherHandler.new('Doe')

scheduler.every '10m', oh
scheduler.in '3d5m', oh
```

The call method must accept 2 (job, time), 1 (job) or 0 arguments.

Note that time is the time when the job got cleared for triggering. If there are mutexes involved, now = mutex_wait_time + time...


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

### :first_at, :first_in, :first

This option is for repeat jobs (cron / every) only.

It's used to specify the first time after which the repeat job should trigger for the first time.

In the case of an "every" job, this will be the first time (module the scheduler frequency) the job triggers.
For a "cron" job, it's the time after which the first schedule will trigger.

```ruby
scheduler.every '2d', :first_at => Time.now + 10 * 3600 do
  # ... every two days, but start in 10 hours
end

scheduler.every '2d', :first_in => '10h' do
  # ... every two days, but start in 10 hours
end
```

:first, :first_at and :first_in all accept a point in time or a duration (number or time string). Use the symbol you think make your schedule more readable.

Note: it's OK to change the first_at (a Time instance) directly:
```ruby
job.first_at = Time.now + 10
job.first_at = Rufus::Scheduler.parse('2029-12-12')
```

### :last_at, :last_in, :last

This option is for repeat jobs (cron / every) only.

It indicates the point in time after which the job should unschedule itself.

```ruby
scheduler.cron '5 23 * * *', :last_in => '10d' do
  # ... do something every evening at 23:05 for 10 days
end

scheduler.every '10m', :last_at => Time.now + 10 * 3600 do
  # ... do something every 10 minutes for 10 hours
end

scheduler.every '10m', :last_in => 10 * 3600 do
  # ... do something every 10 minutes for 10 hours
end
```
:last, :last_at and :last_in all accept a point in time or a duration (number or time string). Use the symbol you think make your schedule more readable.

Note: it's OK to change the last_at (nil or a Time instance) directly:
```ruby
job.last_at = nil
  # remove the "last" bound

job.last_at = Rufus::Scheduler.parse('2029-12-12')
  # set the last bound
```

### :times => nb of times (before auto-unscheduling)

One can tell how many times a repeat job (CronJob or EveryJob) is to execute before unscheduling by itself.

```ruby
scheduler.every '2d', :times => 10 do
  # ... do something every two days, but not more than 10 times
end

scheduler.cron '0 23 * * *', :times => 31 do
  # ... do something every day at 23:00 but do it no more than 31 times
end
```

It's OK to assign nil to :times to make sure the repeat job is not limited. It's useful when the :times is determined at scheduling time.

```ruby
scheduler.cron '0 23 * * *', :times => nolimit ? nil : 10 do
  # ...
end
```

The value set by :times is accessible in the job. It can be modified anytime.

```
job =
  scheduler.cron '0 23 * * *' do
    # ...
  end

# later on...

job.times = 10
  # 10 days and it will be over
```


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

Returns the job id.

```ruby
job = scheduler.schedule_in('10d') do; end
job.id
  # => "in_1374072446.8923042_0.0_0"
```

### scheduler

Returns the scheduler instance itself.

### opts

Returns the options passed at the Job creation.

```ruby
job = scheduler.schedule_in('10d', :tag => 'hello') do; end
job.opts
  # => { :tag => 'hello' }
```

### original

Returns the original schedule.

```ruby
job = scheduler.schedule_in('10d', :tag => 'hello') do; end
job.original
  # => '10d'
```

### callable, handler

callable() returns the scheduled block (or the call method of the callable object passed in lieu of a block)

handler() returns nil if a block was scheduled and the instance scheduled else.

```ruby
# when passing a block

job =
  scheduler.schedule_in('10d') do
    # ...
  end

job.handler
  # => nil
job.callable
  # => #<Proc:0x00000001dc6f58@/home/jmettraux/whatever.rb:115>
```
and

```ruby
# when passing something else than a block

class MyHandler
  attr_reader :counter
  def initialize
    @counter = 0
  end
  def call(job, time)
    @counter = @counter + 1
  end
end

job = scheduler.schedule_in('10d', MyHandler.new)

job.handler
  # => #<Method: MyHandler#call>
job.callable
  # => #<MyHandler:0x0000000163ae88 @counter=0>
```


### scheduled_at

Returns the Time instance when the job got created.

```ruby
job = scheduler.schedule_in('10d', :tag => 'hello') do; end
job.scheduled_at
  # => 2013-07-17 23:48:54 +0900
```

### last_time

Returns the last time the job triggered (is usually nil for AtJob and InJob).
k
```ruby
job = scheduler.schedule_every('1d') do; end
# ...
job.scheduled_at
  # => 2013-07-17 23:48:54 +0900
```

### unschedule

Unschedule the job, preventing it from firing again and removing it from the schedule. This doesn't prevent a running thread for this job to run until its end.

### threads

Returns the list of threads currently "hosting" runs of this Job instance.

### kill

Kills all the currently running threads hosting runs of this Job instance.

Nota bene: this doesn't unschedule the Job instance.

### running?

Returns true if there is at least one running Thread hosting a run of this Job instance.

### pause, resume, paused?, paused_at

These four methods are only available to CronJob and EveryJob instances. One can pause or resume such a job thanks to them.

```ruby
job =
  scheduler.schedule_every('10s') do
    # ...
  end

job.pause
  # => 2013-07-20 01:22:22 +0900
job.paused?
  # => true
job.paused_at
  # => 2013-07-20 01:22:22 +0900

job.resume
  # => nil
```

### tags

Returns the list of tags attached to this Job instance.

By default, returns an empty array.

```ruby
job = scheduler.schedule_in('10d') do; end
job.tags
  # => []

job = scheduler.schedule_in('10d', :tag => 'hello') do; end
job.tags
  # => [ 'hello' ]
```

## AtJob and InJob methods
### time

## EveryJob and CronJob methods

Nothing in particular.

## EveryJob methods

### frequency

It returns the scheduling frequency. For a job scheduled "every 20s", it's 20.

It's used to determine if the job frequency is higher than the scheduler frequency (it raises an ArgumentError if that is the case).

### next_time

## CronJob methods

### frequency

It returns the shortest interval of time between two potential occurences of the job.

For instance:
```ruby
Rufus::Scheduler.parse('* * * * *').frequency         # ==> 60
Rufus::Scheduler.parse('* * * * * *').frequency       # ==> 1

Rufus::Scheduler.parse('5 23 * * *').frequency        # ==> 24 * 3600
Rufus::Scheduler.parse('5 * * * *').frequency         # ==> 3600
Rufus::Scheduler.parse('10,20,30 * * * *').frequency  # ==> 600
```

It's used to determine if the job frequency is higher than the scheduler frequency (it raises an ArgumentError if that is the case).

### next_time


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

### Scheduler#jobs(:tag / :tags => x)

When scheduling a job, one can specify one or more tags attached to the job. These can be used to lookup the job later on.

```ruby
  scheduler.in '10d', :tag => 'main_process' do
    # ...
  end
  scheduler.in '10d', :tags => [ 'main_process', 'side_dish' ] do
    # ...
  end

  # ...

  jobs = scheduler.jobs(:tag => 'main_process')
    # find all the jobs with the 'main_process' tag

  jobs = scheduler.jobs(:tags => [ 'main_process', 'side_dish' ]
    # find all the jobs with the 'main_process' AND 'side_dish' tags
```

### Scheduler#running_jobs

Returns the list of Job instance that have currently running instances.

Whereas other "_jobs" method scan the scheduled job list, this method scans the thread list to find the job. It thus comprises jobs that are running but are not scheduled anymore (that happens for at and in jobs).


## misc Scheduler methods

### Scheduler#unschedule(job_or_job_id)

Unschedule a job given directly or by its id.

### Scheduler#terminate_all_jobs

Unschedules all the jobs, then block until all the jobs that were running terminate.

### Scheduler#shutdown

Shuts down the scheduler, ceases any scheduler/triggering activity.

### Scheduler#shutdown(:terminate)

Calls Scheduler#terminate_all_jobs then shuts down the scheduler. That means this shutdown variant blocks until all the jobs are terminated and then shuts down.

### Scheduler#shutdown(:kill)

Kills all the job (threads) and then shuts the scheduler down. Radical.

### Scheduler#join

Let's the current thread join the scheduling thread in rufus-scheduler. The thread comes back when the scheduler gets shut down.

### Scheduler#threads
### Scheduler#work_threads(query=:all/:active/:vacant)


## Rufus::Scheduler.new options

### :frequency

By default, rufus-scheduler sleeps 0.300 second between every step. At each step it checks for jobs to trigger and so on.

The :frequency option lets you change that 0.300 second to something else.

```ruby
  scheduler = Rufus::Scheduler.new(:frequency => 5)
```

It's OK to use a time string to specify the frequency.

```ruby
  scheduler = Rufus::Scheduler.new(:frequency => '2h10m')
    # this scheduler will sleep 2 hours and 10 minutes between every "step"
```

Use with care.


## parsing cronlines and time strings

TODO


## license

MIT, see [LICENSE.txt](LICENSE.txt)

