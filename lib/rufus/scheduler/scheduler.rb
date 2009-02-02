#
#--
# Copyright (c) 2006-2009, John Mettraux, jmettraux@gmail.com
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#++
#

#
# "made in Japan"
#
# John Mettraux at openwfe.org
#

require 'thread'
require 'rufus/scheduler/otime'
require 'rufus/scheduler/jobs'
require 'rufus/scheduler/cronline'


module Rufus

  #
  # The Scheduler is used by OpenWFEru for registering 'at' and 'cron' jobs.
  # 'at' jobs to execute once at a given point in time. 'cron' jobs
  # execute a specified intervals.
  # The two main methods are thus schedule_at() and schedule().
  #
  # schedule_at() and schedule() await either a Schedulable instance and
  # params (usually an array or nil), either a block, which is more in the
  # Ruby way.
  #
  # == The gem "rufus-scheduler"
  #
  # This scheduler was previously known as the "openwferu-scheduler" gem.
  #
  # To ensure that code tapping the previous gem still runs fine with
  # "rufus-scheduler", this new gem has 'pointers' for the old class
  # names.
  #
  #  require 'rubygems'
  #  require 'openwfe/util/scheduler'
  #  s = OpenWFE::Scheduler.new
  #
  # will still run OK with "rufus-scheduler".
  #
  # == Examples
  #
  #  require 'rubygems'
  #  require 'rufus/scheduler'
  #
  #  scheduler = Rufus::Scheduler.start_new
  #
  #  scheduler.schedule_in("3d") do
  #    regenerate_monthly_report()
  #  end
  #    #
  #    # will call the regenerate_monthly_report method
  #    # in 3 days from now
  #
  #   scheduler.schedule "0 22 * * 1-5" do
  #     log.info "activating security system..."
  #     activate_security_system()
  #   end
  #
  #   job_id = scheduler.schedule_at "Sun Oct 07 14:24:01 +0900 2009" do
  #     init_self_destruction_sequence()
  #   end
  #
  #   scheduler.join # join the scheduler (prevents exiting)
  #
  #
  # an example that uses a Schedulable class :
  #
  #  class Regenerator < Schedulable
  #    def trigger (frequency)
  #      self.send(frequency)
  #    end
  #    def monthly
  #      # ...
  #    end
  #    def yearly
  #      # ...
  #    end
  #  end
  #
  #  regenerator = Regenerator.new
  #
  #  scheduler.schedule_in("4d", regenerator)
  #    #
  #    # will regenerate the report in four days
  #
  #  scheduler.schedule_in(
  #    "5d",
  #    { :schedulable => regenerator, :scope => :month })
  #      #
  #      # will regenerate the monthly report in 5 days
  #
  # There is also schedule_every() :
  #
  #   scheduler.schedule_every("1h20m") do
  #     regenerate_latest_report()
  #   end
  #
  # (note : a schedule every isn't triggered immediately, thus this example
  # will first trigger 1 hour and 20 minutes after being scheduled)
  #
  # The scheduler has a "exit_when_no_more_jobs" attribute. When set to
  # 'true', the scheduler will exit as soon as there are no more jobs to
  # run.
  # Use with care though, if you create a scheduler, set this attribute
  # to true and start the scheduler, the scheduler will immediately exit.
  # This attribute is best used indirectly : the method
  # join_until_no_more_jobs() wraps it.
  #
  # The :scheduler_precision can be set when instantiating the scheduler.
  #
  #   scheduler = Rufus::Scheduler.new(:scheduler_precision => 0.500)
  #   scheduler.start
  #     #
  #     # instatiates a scheduler that checks its jobs twice per second
  #     # (the default is 4 times per second (0.250))
  #
  # Note that rufus-scheduler places a constraint on the values for the
  # precision : 0.0 < p <= 1.0
  # Thus
  #
  #   scheduler.precision = 4.0
  #
  # or
  #
  #   scheduler = Rufus::Scheduler.new :scheduler_precision => 5.0
  #
  # will raise an exception.
  #
  #
  # == Tags
  #
  # Tags can be attached to jobs scheduled :
  #
  #   scheduler.schedule_in "2h", :tags => "backup" do
  #     init_backup_sequence()
  #   end
  #
  #   scheduler.schedule "0 24 * * *", :tags => "new_day" do
  #     do_this_or_that()
  #   end
  #
  #   jobs = find_jobs 'backup'
  #   jobs.each { |job| job.unschedule }
  #
  # Multiple tags may be attached to a single job :
  #
  #   scheduler.schedule_in "2h", :tags => [ "backup", "important" ]  do
  #     init_backup_sequence()
  #   end
  #
  # The vanilla case for tags assume they are String instances, but nothing
  # prevents you from using anything else. The scheduler has no persistence
  # by itself, so no serialization issue.
  #
  #
  # == Cron up to the second
  #
  # A cron schedule can be set at the second level :
  #
  #   scheduler.schedule "7 * * * * *" do
  #     puts "it's now the seventh second of the minute"
  #   end
  #
  # The rufus scheduler recognizes an optional first column for second
  # scheduling. This column can, like for the other columns, specify a
  # value ("7"), a list of values ("7,8,9,27") or a range ("7-12").
  #
  #
  # == information passed to schedule blocks
  #
  # When calling schedule_every(), schedule_in() or schedule_at(), the block
  # expects zero or 3 parameters like in
  #
  #   scheduler.schedule_every("1h20m") do |job_id, at, params|
  #       puts "my job_id is #{job_id}"
  #   end
  #
  # For schedule(), zero or two parameters can get passed
  #
  #   scheduler.schedule "7 * * * * *" do |job_id, cron_line, params|
  #     puts "my job_id is #{job_id}"
  #   end
  #
  # In both cases, params corresponds to the params passed to the schedule
  # method (:tags, :first_at, :first_in, :dont_reschedule, ...)
  #
  #
  # == Exceptions
  #
  # The rufus scheduler will output a stacktrace to the STDOUT in
  # case of exception. There are two ways to change that behaviour.
  #
  #   # 1 - providing a lwarn method to the scheduler instance :
  #
  #   class << scheduler
  #     def lwarn (&block)
  #       puts "oops, something wrong happened : "
  #       puts block.call
  #     end
  #   end
  #
  #     # or
  #
  #   def scheduler.lwarn (&block)
  #     puts "oops, something wrong happened : "
  #     puts block.call
  #   end
  #
  #   # 2 - overriding the [protected] method log_exception(e) :
  #
  #   class << scheduler
  #     def log_exception (e)
  #       puts "something wrong happened : "+e.to_s
  #     end
  #   end
  #
  #     # or
  #
  #   def scheduler.log_exception (e)
  #     puts "something wrong happened : "+e.to_s
  #   end
  #
  # == 'Every jobs' and rescheduling
  #
  # Every jobs can reschedule/unschedule themselves. A reschedule example :
  #
  #   schedule.schedule_every "5h" do |job_id, at, params|
  #
  #     mails = $inbox.fetch_mails
  #     mails.each { |m| $inbox.mark_as_spam(m) if is_spam(m) }
  #
  #     params[:every] = if mails.size > 100
  #       "1h" # lots of spam, check every hour
  #     else
  #       "5h" # normal schedule, every 5 hours
  #     end
  #   end
  #
  # Unschedule example :
  #
  #   schedule.schedule_every "10s" do |job_id, at, params|
  #     #
  #     # polls every 10 seconds until a mail arrives
  #
  #     $mail = $inbox.fetch_last_mail
  #
  #     params[:dont_reschedule] = true if $mail
  #   end
  #
  # == 'Every jobs', :first_at and :first_in
  #
  # Since rufus-scheduler 1.0.2, the schedule_every methods recognizes two
  # optional parameters, :first_at and :first_in
  #
  #   scheduler.schedule_every "2d", :first_in => "5h" do
  #     # schedule something every two days, start in 5 hours...
  #   end
  #
  #   scheduler.schedule_every "2d", :first_at => "5h" do
  #     # schedule something every two days, start in 5 hours...
  #   end
  #
  # == job.next_time()
  #
  # Jobs, be they at, every or cron have a next_time() method, which tells
  # when the job will be fired next time (for at and in jobs, this is also the
  # last time).
  #
  # For cron jobs, the current implementation is quite brutal. It takes three
  # seconds on my 2006 macbook to reach a cron schedule 1 year away.
  #
  # When is the next friday 13th ?
  #
  #   require 'rubygems'
  #   require 'rufus/scheduler'
  #
  #   puts Rufus::CronLine.new("* * 13 * fri").next_time
  #
  #
  # == :thread_name option
  #
  # You can specify the name of the scheduler's thread. Should make
  # it easier in some debugging situations.
  #
  #   scheduler.new :thread_name => "the crazy scheduler"
  #
  #
  # == job.trigger_thread
  #
  # Since rufus-scheduler 1.0.8, you can have access to the thread of
  # a job currently being triggered.
  #
  #   job = scheduler.get_job(job_id)
  #   thread = job.trigger_thread
  #
  # This new method will return nil if the job is not currently being
  # triggered. Not that in case of an every or cron job, this method
  # will return the thread of the last triggered instance, thus, in case
  # of overlapping executions, you only get the most recent thread.
  #
  #
  # == specifying a :timeout for a job
  #
  # rufus-scheduler 1.0.12 introduces a :timeout parameter for jobs.
  #
  #   scheduler.every "3h", :timeout => '2h30m' do
  #     do_that_long_job()
  #   end
  #
  # after 2 hours and half, the 'long job' will get interrupted by a
  # Rufus::TimeOutError (so that you know what to catch).
  #
  # :timeout is applicable to all types of jobs : at, in, every, cron. It
  # accepts a String value following the "Mdhms" scheme the rufus-scheduler
  # uses.
  #
  class Scheduler

    VERSION = '1.0.13'

    #
    # By default, the precision is 0.250, with means the scheduler
    # will check for jobs to execute 4 times per second.
    #
    attr_reader :precision

    #
    # Setting the precision ( 0.0 < p <= 1.0 )
    #
    def precision= (f)

      raise 'precision must be 0.0 < p <= 1.0' \
        if f <= 0.0 or f > 1.0

      @precision = f
    end

    #--
    # Set by default at 0.00045, it's meant to minimize drift
    #
    #attr_accessor :correction
    #++

    #
    # As its name implies.
    #
    attr_accessor :stopped


    def initialize (params={})

      super()

      @pending_jobs = []
      @cron_jobs = {}
      @non_cron_jobs = {}

      @schedule_queue = Queue.new
      @unschedule_queue = Queue.new
        #
        # sync between the step() method and the [un]schedule
        # methods is done via these queues, no more mutex

      @scheduler_thread = nil

      @precision = 0.250
        # every 250ms, the scheduler wakes up (default value)
      begin
        self.precision = Float(params[:scheduler_precision])
      rescue Exception => e
        # let precision at its default value
      end

      @thread_name = params[:thread_name] || 'rufus scheduler'

      #@correction = 0.00045

      @exit_when_no_more_jobs = false
      #@dont_reschedule_every = false

      @last_cron_second = -1

      @stopped = true
    end

    #
    # Starts this scheduler (or restart it if it was previously stopped)
    #
    def start

      @stopped = false

      @scheduler_thread = Thread.new do

        #Thread.current[:name] = @thread_name
          # doesn't work with Ruby 1.9.1

        #if defined?(JRUBY_VERSION)
        #  require 'java'
        #  java.lang.Thread.current_thread.name = @thread_name
        #end
          # not necessary anymore (JRuby 1.1.6)

        loop do

          break if @stopped

          t0 = Time.now.to_f

          step

          d = Time.now.to_f - t0 # + @correction

          next if d > @precision

          sleep(@precision - d)
        end
      end

      @scheduler_thread[:name] = @thread_name
    end

    #
    # Instantiates a new Rufus::Scheduler instance, starts it and returns it
    #
    def self.start_new (params = {})

      s = self.new(params)
      s.start
      s
    end

    #
    # The scheduler is stoppable via sstop()
    #
    def stop

      @stopped = true
    end

    # (for backward compatibility)
    #
    alias :sstart :start

    # (for backward compatibility)
    #
    alias :sstop :stop

    #
    # Joins on the scheduler thread
    #
    def join

      @scheduler_thread.join
    end

    #
    # Like join() but takes care of setting the 'exit_when_no_more_jobs'
    # attribute of this scheduler to true before joining.
    # Thus the scheduler will exit (and the join terminates) as soon as
    # there aren't no more 'at' (or 'every') jobs in the scheduler.
    #
    # Currently used only in unit tests.
    #
    def join_until_no_more_jobs

      @exit_when_no_more_jobs = true
      join
    end

    #
    # Ensures that a duration is a expressed as a Float instance.
    #
    #   duration_to_f("10s")
    #
    # will yield 10.0
    #
    def duration_to_f (s)

      Rufus.duration_to_f(s)
    end

    #--
    #
    # The scheduling methods
    #
    #++

    #
    # Schedules a job by specifying at which time it should trigger.
    # Returns the a job_id that can be used to unschedule the job.
    #
    # This method returns a job identifier which can be used to unschedule()
    # the job.
    #
    # If the job is specified in the past, it will be triggered immediately
    # but not scheduled.
    # To avoid the triggering, the parameter :discard_past may be set to
    # true :
    #
    #   jobid = scheduler.schedule_at(yesterday, :discard_past => true) do
    #     puts "you'll never read this message"
    #   end
    #
    # And 'jobid' will hold a nil (not scheduled).
    #
    #
    def schedule_at (at, params={}, &block)

      do_schedule_at(
        at,
        prepare_params(params),
        &block)
    end

    #
    # a shortcut for schedule_at
    #
    alias :at :schedule_at


    #
    # Schedules a job by stating in how much time it should trigger.
    # Returns the a job_id that can be used to unschedule the job.
    #
    # This method returns a job identifier which can be used to unschedule()
    # the job.
    #
    def schedule_in (duration, params={}, &block)

      do_schedule_at(
        Time.new.to_f + Rufus.duration_to_f(duration),
        prepare_params(params),
        &block)
    end

    #
    # a shortcut for schedule_in
    #
    alias :in :schedule_in

    #
    # Schedules a job in a loop. After an execution, it will not execute
    # before the time specified in 'freq'.
    #
    # This method returns a job identifier which can be used to unschedule()
    # the job.
    #
    # In case of exception in the job, it will be rescheduled. If you don't
    # want the job to be rescheduled, set the parameter :try_again to false.
    #
    #   scheduler.schedule_every "500", :try_again => false do
    #     do_some_prone_to_error_stuff()
    #       # won't get rescheduled in case of exception
    #   end
    #
    # Since rufus-scheduler 1.0.2, the params :first_at and :first_in are
    # accepted.
    #
    #   scheduler.schedule_every "2d", :first_in => "5h" do
    #     # schedule something every two days, start in 5 hours...
    #   end
    #
    # (without setting a :first_in (or :first_at), our example schedule would
    # have had been triggered after two days).
    #
    def schedule_every (freq, params={}, &block)

      params = prepare_params(params)
      params[:every] = freq

      first_at = params[:first_at]
      first_in = params[:first_in]

      #params[:delayed] = true if first_at or first_in

      first_at = if first_at
        at_to_f(first_at)
      elsif first_in
        Time.now.to_f + Rufus.duration_to_f(first_in)
      else
        Time.now.to_f + Rufus.duration_to_f(freq) # not triggering immediately
      end

      do_schedule_at(first_at, params, &block)
    end

    #
    # a shortcut for schedule_every
    #
    alias :every :schedule_every

    #
    # Schedules a cron job, the 'cron_line' is a string
    # following the Unix cron standard (see "man 5 crontab" in your command
    # line, or http://www.google.com/search?q=man%205%20crontab).
    #
    # For example :
    #
    #  scheduler.schedule("5 0 * * *", s)
    #    # will trigger the schedulable s every day
    #    # five minutes after midnight
    #
    #  scheduler.schedule("15 14 1 * *", s)
    #    # will trigger s at 14:15 on the first of every month
    #
    #  scheduler.schedule("0 22 * * 1-5") do
    #    puts "it's break time..."
    #  end
    #    # outputs a message every weekday at 10pm
    #
    # Returns the job id attributed to this 'cron job', this id can
    # be used to unschedule the job.
    #
    # This method returns a job identifier which can be used to unschedule()
    # the job.
    #
    def schedule (cron_line, params={}, &block)

      params = prepare_params(params)

      #
      # is a job with the same id already scheduled ?

      cron_id = params[:cron_id] || params[:job_id]

      #@unschedule_queue << cron_id

      #
      # schedule

      b = to_block(params, &block)
      job = CronJob.new(self, cron_id, cron_line, params, &b)

      @schedule_queue << job

      job.job_id
    end

    #
    # an alias for schedule()
    #
    alias :cron :schedule

    #--
    #
    # The UNscheduling methods
    #
    #++

    #
    # Unschedules an 'at' or a 'cron' job identified by the id
    # it was given at schedule time.
    #
    def unschedule (job_id)

      @unschedule_queue << job_id
    end

    #
    # Unschedules a cron job
    #
    # (deprecated : use unschedule(job_id) for all the jobs !)
    #
    def unschedule_cron_job (job_id)

      unschedule(job_id)
    end

    #--
    #
    # 'query' methods
    #
    #++

    #
    # Returns the job corresponding to job_id, an instance of AtJob
    # or CronJob will be returned.
    #
    def get_job (job_id)

      @cron_jobs[job_id] || @non_cron_jobs[job_id]
    end

    #
    # Finds a job (via get_job()) and then returns the wrapped
    # schedulable if any.
    #
    def get_schedulable (job_id)

      j = get_job(job_id)
      j.respond_to?(:schedulable) ? j.schedulable : nil
    end

    #
    # Returns an array of jobs that have the given tag.
    #
    def find_jobs (tag=nil)

      jobs = @cron_jobs.values + @non_cron_jobs.values
      jobs = jobs.select { |job| job.has_tag?(tag) } if tag
      jobs
    end

    #
    # Returns all the jobs in the scheduler.
    #
    def all_jobs

      find_jobs
    end

    #
    # Finds the jobs with the given tag and then returns an array of
    # the wrapped Schedulable objects.
    # Jobs that haven't a wrapped Schedulable won't be included in the
    # result.
    #
    def find_schedulables (tag)

      find_jobs(tag).find_all { |job| job.respond_to?(:schedulable) }
    end

    #
    # Returns the number of currently pending jobs in this scheduler
    # ('at' jobs and 'every' jobs).
    #
    def pending_job_count

      @pending_jobs.size
    end

    #
    # Returns the number of cron jobs currently active in this scheduler.
    #
    def cron_job_count

      @cron_jobs.size
    end

    #
    # Returns the current count of 'every' jobs scheduled.
    #
    def every_job_count

      @non_cron_jobs.values.select { |j| j.class == EveryJob }.size
    end

    #
    # Returns the current count of 'at' jobs scheduled (not 'every').
    #
    def at_job_count

      @non_cron_jobs.values.select { |j| j.class == AtJob }.size
    end

    #
    # Returns true if the given string seems to be a cron string.
    #
    def self.is_cron_string (s)

      s.match('.+ .+ .+ .+ .+') # well...
    end

    private

    #
    # the unschedule work itself.
    #
    def do_unschedule (job_id)

      job = get_job job_id

      return (@cron_jobs.delete(job_id) != nil) if job.is_a?(CronJob)

      return false unless job # not found

      if job.is_a?(AtJob) # catches AtJob and EveryJob instances
        @non_cron_jobs.delete(job_id)
        job.params[:dont_reschedule] = true # for AtJob as well, no worries
      end

      for i in 0...@pending_jobs.length
        if @pending_jobs[i].job_id == job_id
          @pending_jobs.delete_at i
          return true # asap
        end
      end

      true
    end

    #
    # Making sure that params is a Hash.
    #
    def prepare_params (params)

      params.is_a?(Schedulable) ? { :schedulable => params } : params
    end

    #
    # The core method behind schedule_at and schedule_in (and also
    # schedule_every). It's protected, don't use it directly.
    #
    def do_schedule_at (at, params={}, &block)

      job = params.delete(:job)

      unless job

        jobClass = params[:every] ? EveryJob : AtJob

        b = to_block(params, &block)

        job = jobClass.new(self, at_to_f(at), params[:job_id], params, &b)
      end

      if jobClass == AtJob && job.at < (Time.new.to_f + @precision)

        job.trigger() unless params[:discard_past]

        @non_cron_jobs.delete job.job_id # just to be sure

        return nil
      end

      @non_cron_jobs[job.job_id] = job

      @schedule_queue << job

      job.job_id
    end

    #
    # Ensures an 'at' instance is translated to a float
    # (to be compared with the float coming from time.to_f)
    #
    def at_to_f (at)

      at = Rufus::to_ruby_time(at) if at.kind_of?(String)
      at = Rufus::to_gm_time(at) if at.kind_of?(DateTime)
      at = at.to_f if at.kind_of?(Time)

      raise "cannot schedule at : #{at.inspect}" unless at.is_a?(Float)

      at
    end

    #
    # Returns a block. If a block is passed, will return it, else,
    # if a :schedulable is set in the params, will return a block
    # wrapping a call to it.
    #
    def to_block (params, &block)

      return block if block

      schedulable = params.delete(:schedulable)

      return nil unless schedulable

      l = lambda do
        schedulable.trigger(params)
      end
      class << l
        attr_accessor :schedulable
      end
      l.schedulable = schedulable

      l
    end

    #
    # Pushes an 'at' job into the pending job list
    #
    def push_pending_job (job)

      old = @pending_jobs.find { |j| j.job_id == job.job_id }
      @pending_jobs.delete(old) if old
        #
        # override previous job with same id

      if @pending_jobs.length < 1 or job.at >= @pending_jobs.last.at
        @pending_jobs << job
        return
      end

      for i in 0...@pending_jobs.length
        if job.at <= @pending_jobs[i].at
          @pending_jobs[i, 0] = job
          return # right place found
        end
      end
    end

    #
    # This is the method called each time the scheduler wakes up
    # (by default 4 times per second). It's meant to quickly
    # determine if there are jobs to trigger else to get back to sleep.
    # 'cron' jobs get executed if necessary then 'at' jobs.
    #
    def step

      step_unschedule
        # unschedules any job in the unschedule queue before
        # they have a chance to get triggered.

      step_trigger
        # triggers eligible jobs

      step_schedule
        # schedule new jobs

      # done.
    end

    #
    # unschedules jobs in the unschedule_queue
    #
    def step_unschedule

      loop do

        break if @unschedule_queue.empty?

        do_unschedule(@unschedule_queue.pop)
      end
    end

    #
    # adds every job waiting in the @schedule_queue to
    # either @pending_jobs or @cron_jobs.
    #
    def step_schedule

      loop do

        break if @schedule_queue.empty?

        j = @schedule_queue.pop

        if j.is_a?(CronJob)

          @cron_jobs[j.job_id] = j

        else # it's an 'at' job

          push_pending_job j
        end
      end
    end

    #
    # triggers every eligible pending (at or every) jobs, then every eligible
    # cron jobs.
    #
    def step_trigger

      now = Time.now

      if @exit_when_no_more_jobs && @pending_jobs.size < 1

        @stopped = true
        return
      end

      # TODO : eventually consider running cron / pending
      # job triggering in two different threads
      #
      # but well... there's the synchronization issue...

      #
      # cron jobs

      if now.sec != @last_cron_second

        @last_cron_second = now.sec

        @cron_jobs.each do |cron_id, cron_job|
          #trigger(cron_job) if cron_job.matches?(now, @precision)
          cron_job.trigger if cron_job.matches?(now)
        end
      end

      #
      # pending jobs

      now = now.to_f
        #
        # that's what at jobs do understand

      loop do

        break if @pending_jobs.length < 1

        job = @pending_jobs[0]

        break if job.at > now

        #if job.at <= now
          #
          # obviously

        job.trigger

        @pending_jobs.delete_at 0
      end
    end

    #
    # If an error occurs in the job, it well get caught and an error
    # message will be displayed to STDOUT.
    # If this scheduler provides a lwarn(message) method, it will
    # be used insted.
    #
    # Of course, one can override this method.
    #
    def log_exception (e)

      message =
        "trigger() caught exception\n" +
        e.to_s + "\n" +
        e.backtrace.join("\n")

      if self.respond_to?(:lwarn)
        lwarn { message }
      else
        puts message
      end
    end
  end

  #
  # This module adds a trigger method to any class that includes it.
  # The default implementation feature here triggers an exception.
  #
  module Schedulable

    def trigger (params)
      raise "trigger() implementation is missing"
    end

    def reschedule (scheduler)
      raise "reschedule() implentation is missing"
    end
  end

  #
  # This error is thrown when the :timeout attribute triggers
  #
  class TimeOutError < RuntimeError
  end
end

