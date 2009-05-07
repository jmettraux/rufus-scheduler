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
#
# Made in Japan.
#++


require 'rufus/sc/rtime'
require 'rufus/sc/cronline'
require 'rufus/sc/jobs'
require 'rufus/sc/jobqueues'


module Rufus::Scheduler

  # This gem's version
  #
  VERSION = '2.0.1'

  #
  # It's OK to pass an object responding to :trigger when scheduling a job
  # (instead of passing a block).
  #
  # This is simply a helper module. The rufus-scheduler will check if scheduled
  # object quack (respond to :trigger anyway).
  #
  module Schedulable
    def call (job)
      trigger(job.params)
    end
    def trigger (params)
      raise NotImplementedError.new('implementation is missing')
    end
  end

  #
  # For backward compatibility
  #
  module ::Rufus::Schedulable
    extend ::Rufus::Scheduler::Schedulable
  end

  # Legacy from the previous version of Rufus-Scheduler.
  #
  # Consider all methods here as 'deprecated'.
  #
  module LegacyMethods

    def find_jobs (tag=nil)
      tag ? find_by_tag(tag) : all_jobs.values
    end
    def at_job_count
      @jobs.select(:at).size +
      @jobs.select(:in).size
    end
    def every_job_count
      @jobs.select(:every).size
    end
    def cron_job_count
      @cron_jobs.size
    end
    def pending_job_count
      @jobs.size
    end
    def precision
      @frequency
    end
  end

  #
  # The core of a rufus-scheduler. See implementations like
  # Rufus::Scheduler::PlainScheduler and Rufus::Scheduler::EmScheduler for
  # directly usable stuff.
  #
  class SchedulerCore

    include LegacyMethods

    # classical options hash
    #
    attr_reader :options

    # Instantiates a Rufus::Scheduler.
    #
    def initialize (opts={})

      @options = opts

      @jobs = JobQueue.new
      @cron_jobs = CronJobQueue.new

      @frequency = @options[:frequency] || 0.330
    end

    # Instantiates and starts a new Rufus::Scheduler.
    #
    def self.start_new (opts={})

      s = self.new(opts)
      s.start
      s
    end

    #--
    # SCHEDULE METHODS
    #++

    # Schedules a job in a given amount of time.
    #
    #   scheduler.in '20m' do
    #     puts "order ristretto"
    #   end
    #
    # will order an espresso (well sort of) in 20 minutes.
    #
    def in (t, s=nil, opts={}, &block)

      add_job(InJob.new(self, t, combine_opts(s, opts), &block))
    end
    alias :schedule_in :in

    # Schedules a job at a given point in time.
    #
    #   scheduler.at 'Thu Mar 26 19:30:00 2009' do
    #     puts 'order pizza'
    #   end
    #
    # pizza is for Thursday at 2000 (if the shop brochure is right).
    #
    def at (t, s=nil, opts={}, &block)

      add_job(AtJob.new(self, t, combine_opts(s, opts), &block))
    end
    alias :schedule_at :at

    # Schedules a recurring job every t.
    #
    #   scheduler.every '5m1w' do
    #     puts 'check blood pressure'
    #   end
    #
    # checking blood pressure every 5 months and 1 week.
    #
    def every (t, s=nil, opts={}, &block)

      add_job(EveryJob.new(self, t, combine_opts(s, opts), &block))
    end
    alias :schedule_every :every

    # Schedules a job given a cron string.
    #
    #   scheduler.cron '0 22 * * 1-5' do
    #     # every day of the week at 00:22
    #     puts 'activate security system'
    #   end
    #
    def cron (cronstring, s=nil, opts={}, &block)

      add_cron_job(CronJob.new(self, cronstring, combine_opts(s, opts), &block))
    end
    alias :schedule :cron

    # Unschedules a job (cron or at/every/in job) given its id.
    #
    # Returns the job that got unscheduled.
    #
    def unschedule (job_id)

      @jobs.unschedule(job_id) || @cron_jobs.unschedule(job_id)
    end

    #--
    # MISC
    #++

    # Feel free to override this method. The default implementation simply
    # outputs the error message to STDOUT
    #
    def handle_exception (job, exception)

      if self.respond_to?(:log_exception)
        #
        # some kind of backward compatibility

        log_exception(exception)

      else

        puts '=' * 80
        puts "scheduler caught exception :"
        puts exception
        puts '=' * 80
      end
    end

    #--
    # JOB LOOKUP
    #++

    # Returns a map job_id => job for at/in/every jobs
    #
    def jobs

      @jobs.to_h
    end

    # Returns a map job_id => job for cron jobs
    #
    def cron_jobs

      @cron_jobs.to_h
    end

    # Returns a map job_id => job of all the jobs currently in the scheduler
    #
    def all_jobs

      jobs.merge(cron_jobs)
    end

    # Returns a list of jobs with the given tag
    #
    def find_by_tag (tag)

      all_jobs.values.select { |j| j.tags.include?(tag) }
    end

    protected

    def combine_opts (schedulable, opts)

      if schedulable.respond_to?(:trigger)

        opts[:schedulable] = schedulable

      elsif schedulable != nil

        opts = schedulable.merge(opts)
      end

      opts
    end

    # The method that does the "wake up and trigger any job that should get
    # triggered.
    #
    def step
      cron_step
      at_step
    end

    # calls every second
    #
    def cron_step

      now = Time.now
      return if now.sec == @last_cron_second
      @last_cron_second = now.sec
        #
        # ensuring the crons are checked within 1 second (not 1.2 second)

      @cron_jobs.trigger_matching_jobs(now)
    end

    def at_step

      while job = @jobs.job_to_trigger
        job.trigger
      end
    end

    def add_job (job)

      complain_if_blocking_and_timeout(job)

      return if job.params[:discard_past] && Time.now.to_f >= job.at

      @jobs << job

      job
    end

    def add_cron_job (job)

      complain_if_blocking_and_timeout(job)

      @cron_jobs << job

      job
    end

    # Raises an error if the job has the params :blocking and :timeout set
    #
    def complain_if_blocking_and_timeout (job)

      raise(
        ArgumentError.new('cannot set a :timeout on a :blocking job')
      ) if job.params[:blocking] and job.params[:timeout]
    end

    # The default, plain, implementation. If 'blocking' is true, will simply
    # call the block and return when the block is done.
    # Else, it will call the block in a dedicated thread.
    #
    # TODO : clarify, the blocking here blocks the whole scheduler, while
    # EmScheduler blocking triggers for the next tick. Not the same thing ...
    #
    def trigger_job (blocking, &block)

      if blocking
        block.call
      else
        Thread.new { block.call }
      end
    end
  end

  #--
  # SCHEDULER 'IMPLEMENTATIONS'
  #++

  #
  # A classical implementation, uses a sleep/step loop in a thread (like the
  # original rufus-scheduler).
  #
  class PlainScheduler < SchedulerCore

    def start

      @thread = Thread.new do
        loop do
          sleep(@frequency)
          self.step
        end
      end

      @thread[:name] =
        @options[:thread_name] ||
        "#{self.class} - #{Rufus::Scheduler::VERSION}"
    end

    def stop (opts={})

      @thread.exit
    end

    def join

      @thread.join
    end
  end

  # TODO : investigate idea
  #
  #class BlockingScheduler < PlainScheduler
  #  # use a Queue and a worker thread for the 'blocking' jobs
  #end

  #
  # A rufus-scheduler that uses an EventMachine periodic timer instead of a
  # loop.
  #
  class EmScheduler < SchedulerCore

    def initialize (opts={})

      raise LoadError.new(
        'EventMachine missing, "require \'eventmachine\'" might help'
      ) unless defined?(EM)

      super
    end

    def start

      @em_thread = nil

      unless EM.reactor_running?
        @em_thread = Thread.new { EM.run }
        while (not EM.reactor_running?)
          Thread.pass
        end
      end

      #unless EM.reactor_running?
      #  t = Thread.current
      #  @em_thread = Thread.new { EM.run { t.wakeup } }
      #  Thread.stop # EM will wake us up when it's ready
      #end

      @timer = EM::PeriodicTimer.new(@frequency) { step }
    end

    # Stops the scheduler.
    #
    # If the :stop_em option is passed and set to true, it will stop the
    # EventMachine (but only if it started the EM by itself !).
    #
    def stop (opts={})

      @timer.cancel

      EM.stop if opts[:stop_em] and @em_thread
    end

    # Joins this scheduler. Will actually join it only if it started the
    # underlying EventMachine.
    #
    def join

      @em_thread.join if @em_thread
    end

    protected

    # If 'blocking' is set to true, the block will get called at the
    # 'next_tick'. Else the block will get called via 'defer' (own thread).
    #
    def trigger_job (blocking, &block)

      m = blocking ? :next_tick : :defer
        #
        # :next_tick monopolizes the EM
        # :defer executes its block in another thread

      EM.send(m) { block.call }
    end
  end

  #
  # This error is thrown when the :timeout attribute triggers
  #
  class TimeOutError < RuntimeError
  end
end

