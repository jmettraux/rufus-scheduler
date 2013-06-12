#--
# Copyright (c) 2006-2013, John Mettraux, jmettraux@gmail.com
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


require 'rufus/sc/version'
require 'rufus/sc/rtime'
require 'rufus/sc/cronline'
require 'rufus/sc/jobs'
require 'rufus/sc/jobqueues'


module Rufus::Scheduler

  #
  # It's OK to pass an object responding to :trigger when scheduling a job
  # (instead of passing a block).
  #
  # This is simply a helper module. The rufus-scheduler will check if scheduled
  # object quack (respond to :trigger anyway).
  #
  module Schedulable
    def call(job)
      trigger(job.params)
    end
    def trigger(params)
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

    def find_jobs(tag=nil)
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
    def initialize(opts={})

      @options = opts

      @jobs = get_queue(:at, opts)
      @cron_jobs = get_queue(:cron, opts)

      @frequency = @options[:frequency] || 0.330

      @mutexes = {}
    end

    # Instantiates and starts a new Rufus::Scheduler.
    #
    def self.start_new(opts={})

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
    def in(t, s=nil, opts={}, &block)

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
    def at(t, s=nil, opts={}, &block)

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
    def every(t, s=nil, opts={}, &block)

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
    def cron(cronstring, s=nil, opts={}, &block)

      add_cron_job(CronJob.new(self, cronstring, combine_opts(s, opts), &block))
    end
    alias :schedule :cron

    # Unschedules a job (cron or at/every/in job).
    #
    # Returns the job that got unscheduled.
    #
    def unschedule(job_or_id)

      job_id = job_or_id.respond_to?(:job_id) ? job_or_id.job_id : job_or_id

      @jobs.unschedule(job_id) || @cron_jobs.unschedule(job_id)
    end

    # Given a tag, unschedules all the jobs that bear that tag.
    #
    def unschedule_by_tag(tag)

      jobs = find_by_tag(tag)
      jobs.each { |job| unschedule(job.job_id) }

      jobs
    end

    # Pauses a given job. If the argument is an id (String) and the
    # corresponding job cannot be found, an ArgumentError will get raised.
    #
    def pause(job_or_id)

      find(job_or_id).pause
    end

    # Resumes a given job. If the argument is an id (String) and the
    # corresponding job cannot be found, an ArgumentError will get raised.
    #
    def resume(job_or_id)

      find(job_or_id).resume
    end

    #--
    # MISC
    #++

    # Determines if there is #log_exception, #handle_exception or #on_exception
    # method. If yes, hands the exception to it, else defaults to outputting
    # details to $stderr.
    #
    def do_handle_exception(job, exception)

      begin

        [ :log_exception, :handle_exception, :on_exception ].each do |m|

          next unless self.respond_to?(m)

          if method(m).arity == 1
            self.send(m, exception)
          else
            self.send(m, job, exception)
          end

          return
            # exception was handled successfully
        end

      rescue Exception => e

        $stderr.puts '*' * 80
        $stderr.puts 'the exception handling method itself had an issue:'
        $stderr.puts e
        $stderr.puts *e.backtrace
        $stderr.puts '*' * 80
      end

      $stderr.puts '=' * 80
      $stderr.puts 'scheduler caught exception:'
      $stderr.puts exception
      $stderr.puts *exception.backtrace
      $stderr.puts '=' * 80
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
    def find_by_tag(tag)

      all_jobs.values.select { |j| j.tags.include?(tag) }
    end

    # Mostly used to find a job given its id. If the argument is a job, will
    # simply return it.
    #
    # If the argument is an id, and no job with that id is found, it will
    # raise an ArgumentError.
    #
    def find(job_or_id)

      return job_or_id if job_or_id.respond_to?(:job_id)

      job = all_jobs[job_or_id]

      raise ArgumentError.new(
        "couldn't find job #{job_or_id.inspect}"
      ) unless job

      job
    end

    # Returns the current list of trigger threads (threads) dedicated to
    # the execution of jobs.
    #
    def trigger_threads

      Thread.list.select { |t|
        t["rufus_scheduler__trigger_thread__#{self.object_id}"]
      }
    end

    # Returns the list of the currently running jobs (jobs that just got
    # triggered and are executing).
    #
    def running_jobs

      Thread.list.collect { |t|
        t["rufus_scheduler__trigger_thread__#{self.object_id}"]
      }.compact
    end

    # This is a blocking call, it will return when all the jobs have been
    # unscheduled, waiting for any running one to finish before unscheduling
    # it.
    #
    def terminate_all_jobs

      all_jobs.each do |job_id, job|
        job.unschedule
      end

      while running_jobs.size > 0
        sleep 0.01
      end
    end

    protected

    # Returns a job queue instance.
    #
    # (made it into a method for easy override)
    #
    def get_queue(type, opts)

      q = if type == :cron
        opts[:cron_job_queue] || Rufus::Scheduler::CronJobQueue.new
      else
        opts[:job_queue] || Rufus::Scheduler::JobQueue.new
      end

      q.scheduler = self if q.respond_to?(:scheduler=)

      q
    end

    def combine_opts(schedulable, opts)

      if schedulable.respond_to?(:trigger) || schedulable.respond_to?(:call)

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

      @cron_jobs.trigger_matching_jobs
      @jobs.trigger_matching_jobs
    end

    def add_job(job)

      complain_if_blocking_and_timeout(job)

      return nil if job.params[:discard_past] && Time.now.to_f >= job.at

      @jobs << job

      job
    end

    def add_cron_job(job)

      complain_if_blocking_and_timeout(job)

      @cron_jobs << job

      job
    end

    # Raises an error if the job has the params :blocking and :timeout set
    #
    def complain_if_blocking_and_timeout(job)

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
    def trigger_job(params, &block)

      if params[:blocking]
        block.call
      elsif m = params[:mutex]
        Thread.new { synchronize_with_mutex(m, &block) }
      else
        Thread.new { block.call }
      end
    end

    def synchronize_with_mutex(mutex, &block)
      case mutex
      when Mutex
        mutex.synchronize { block.call }
      when Array
        mutex.reduce(block) do |memo, m|
          m = (@mutexes[m.to_s] ||= Mutex.new) unless m.is_a?(Mutex)
          lambda { m.synchronize { memo.call } }
        end.call
      else
        (@mutexes[mutex.to_s] ||= Mutex.new).synchronize { block.call }
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
          step
        end
      end

      @thread[:name] =
        @options[:thread_name] ||
        "#{self.class} - #{Rufus::Scheduler::VERSION}"
    end

    # Stops this scheduler.
    #
    # == :terminate => true
    #
    # If the option :terminate is set to true,
    # the method will return once all the jobs have been unscheduled and
    # are done with their current run if any.
    #
    # (note that if a job is
    # currently running, this method will wait for it to terminate, it
    # will not interrupt the job run).
    #
    def stop(opts={})

      @thread.exit

      terminate_all_jobs if opts[:terminate]
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
  # A rufus-scheduler that steps only when the ruby process receives the
  # 10 / USR1 signal.
  #
  class SignalScheduler < SchedulerCore

    def initialize(opts={})

      super(opts)

      trap(@options[:signal] || 10) do
        step
      end
    end


    # Stops this scheduler.
    #
    # == :terminate => true
    #
    # If the option :terminate is set to true,
    # the method will return once all the jobs have been unscheduled and
    # are done with their current run if any.
    #
    # (note that if a job is
    # currently running, this method will wait for it to terminate, it
    # will not interrupt the job run).
    #
    def stop(opts={})

      trap(@options[:signal] || 10)

      terminate_all_jobs if opts[:terminate]
    end
  end

  #
  # A rufus-scheduler that uses an EventMachine periodic timer instead of a
  # loop.
  #
  class EmScheduler < SchedulerCore

    def initialize(opts={})

      raise LoadError.new(
        'EventMachine missing, "require \'eventmachine\'" might help'
      ) unless defined?(EM)

      super(opts)
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
    # == :stop_em => true
    #
    # If the :stop_em option is passed and set to true, it will stop the
    # EventMachine (but only if it started the EM by itself !).
    #
    # == :terminate => true
    #
    # If the option :terminate is set to true,
    # the method will return once all the jobs have been unscheduled and
    # are done with their current run if any.
    #
    # (note that if a job is
    # currently running, this method will wait for it to terminate, it
    # will not interrupt the job run).
    #
    def stop(opts={})

      @timer.cancel

      terminate_all_jobs if opts[:terminate]

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
    def trigger_job(params, &block)

      # :next_tick monopolizes the EM
      # :defer executes its block in another thread
      # (if I read the doc carefully...)

      if params[:blocking]
        EM.next_tick { block.call }
      elsif m = params[:mutex]
        EM.defer { synchronize_with_mutex(m, &block) }
      else
        EM.defer { block.call }
      end
    end
  end

  #
  # This error is thrown when the :timeout attribute triggers
  #
  class TimeOutError < RuntimeError
  end
end

