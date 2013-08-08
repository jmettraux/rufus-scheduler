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

require 'date' if RUBY_VERSION < '1.9.0'
require 'time'
require 'thread'
require 'tzinfo'


module Rufus

  class Scheduler

    require 'rufus/scheduler/util'
    require 'rufus/scheduler/jobs'
    require 'rufus/scheduler/cronline'

    VERSION = '3.0.0'

    #
    # This error is thrown when the :timeout attribute triggers
    #
    class TimeoutError < StandardError; end

    MIN_WORK_THREADS = 7
    MAX_WORK_THREADS = 35

    attr_accessor :frequency
    attr_reader :started_at
    attr_reader :thread
    attr_reader :thread_key
    attr_reader :mutexes

    attr_accessor :min_work_threads
    attr_accessor :max_work_threads

    attr_reader :work_queue

    def initialize(opts={})

      @started_at = nil
      @paused = false

      @jobs = JobArray.new

      @opts = opts
      @frequency = Rufus::Scheduler.parse(opts[:frequency] || 0.300)
      @mutexes = {}

      @work_queue = Queue.new

      @min_work_threads = opts[:min_work_threads] || MIN_WORK_THREADS
      @max_work_threads = opts[:max_work_threads] || MAX_WORK_THREADS

      @thread_key = "rufus_scheduler_#{self.object_id}"

      start
    end

    # Releasing the gem would probably require redirecting .start_new to
    # .new and emit a simple deprecation message.
    #
    # For now, let's assume the people pointing at rufus-scheduler/master
    # on GitHub know what they do...
    #
    def self.start_new

      fail "this is rufus-scheduler 3.0, use .new instead of .start_new"
    end

    def shutdown(opt=nil)

      @started_at = nil

      jobs.each { |j| j.unschedule }

      @work_queue.clear

      if opt == :wait
        join_all_work_threads
      elsif opt == :kill
        kill_all_work_threads
      end
    end

    alias stop shutdown

    def uptime

      @started_at ? Time.now - @started_at : nil
    end

    def uptime_s

      self.class.to_duration(uptime)
    end

    def join

      @thread.join
    end

    def paused?

      @paused
    end

    def pause

      @paused = true
    end

    def resume

      @paused = false
    end

    #--
    # scheduling methods
    #++

    def at(time, callable=nil, opts={}, &block)

      do_schedule(:once, time, callable, opts, opts[:job], block)
    end

    def schedule_at(time, callable=nil, opts={}, &block)

      do_schedule(:once, time, callable, opts, true, block)
    end

    def in(duration, callable=nil, opts={}, &block)

      do_schedule(:once, duration, callable, opts, opts[:job], block)
    end

    def schedule_in(duration, callable=nil, opts={}, &block)

      do_schedule(:once, duration, callable, opts, true, block)
    end

    def every(duration, callable=nil, opts={}, &block)

      do_schedule(:every, duration, callable, opts, opts[:job], block)
    end

    def schedule_every(duration, callable=nil, opts={}, &block)

      do_schedule(:every, duration, callable, opts, true, block)
    end

    def interval(duration, callable=nil, opts={}, &block)

      do_schedule(:interval, duration, callable, opts, opts[:job], block)
    end

    def schedule_interval(duration, callable=nil, opts={}, &block)

      do_schedule(:interval, duration, callable, opts, true, block)
    end

    def cron(cronline, callable=nil, opts={}, &block)

      do_schedule(:cron, cronline, callable, opts, opts[:job], block)
    end

    def schedule_cron(cronline, callable=nil, opts={}, &block)

      do_schedule(:cron, cronline, callable, opts, true, block)
    end

    def unschedule(job_or_job_id)

      job = job_or_job_id
      job = job(job_or_job_id) if job_or_job_id.is_a?(String)

      job.unschedule
    end

    #--
    # jobs methods
    #++

    # Returns all the scheduled jobs
    # (even those right before re-schedule).
    #
    def jobs(opts={})

      opts = { opts => true } if opts.is_a?(Symbol)

      js =
        (@jobs.to_a + work_threads(:active).collect { |t|
          t[:rufus_scheduler_job]
        }).uniq

      if opts[:running]
        js = js.select { |j| j.running? }
      elsif ! opts[:all]
        js = js.reject { |j| j.unscheduled_at }
      end

      ts = Array(opts[:tag] || opts[:tags]).map { |t| t.to_s }
      js = js.reject { |j| ts.find { |t| ! j.tags.include?(t) } }

      js
    end

    def at_jobs(opts={})

      jobs(opts).select { |j| j.is_a?(Rufus::Scheduler::AtJob) }
    end

    def in_jobs(opts={})

      jobs(opts).select { |j| j.is_a?(Rufus::Scheduler::InJob) }
    end

    def every_jobs(opts={})

      jobs(opts).select { |j| j.is_a?(Rufus::Scheduler::EveryJob) }
    end

    def interval_jobs(opts={})

      jobs(opts).select { |j| j.is_a?(Rufus::Scheduler::IntervalJob) }
    end

    def cron_jobs(opts={})

      jobs(opts).select { |j| j.is_a?(Rufus::Scheduler::CronJob) }
    end

    #def find_by_tag(*tags)
    #  jobs(:tags => tags)
    #end

    def job(job_id)

      @jobs[job_id]
    end

    # Lists all the threads associated with this scheduler.
    #
    def threads

      Thread.list.select { |t| t[thread_key] }
    end

    # Lists all the work threads (the ones actually running the scheduled
    # block code)
    #
    # Accepts a query option, which can be set to:
    # * :all (default), returns all the threads that are work threads
    #   or are currently running a job
    # * :active, returns all threads that are currenly running a job
    # * :vacant, returns the threads that are not running a job
    #
    # If, thanks to :blocking => true, a job is scheduled to monopolize the
    # main scheduler thread, that thread will get returned when :active or
    # :all.
    #
    def work_threads(query=:all)

      ts =
        threads.select { |t|
          t[:rufus_scheduler_job] || t[:rufus_scheduler_work_thread]
        }

      case query
        when :active then ts.select { |t| t[:rufus_scheduler_job] }
        when :vacant then ts.reject { |t| t[:rufus_scheduler_job] }
        else ts
      end
    end

    def running_jobs(opts={})

      jobs(opts.merge(:running => true))
    end

    protected

    def reschedule(job)

      @jobs.push(job)
    end

    def terminate_all_jobs

      jobs.each { |j| j.unschedule }

      sleep 0.01 while running_jobs.size > 0
    end

    def join_all_work_threads

      work_threads.size.times { @work_queue << :sayonara }

      work_threads.each { |t| t.join }

      @work_queue.clear
    end

    def kill_all_work_threads

      work_threads.each { |t| t.kill }
    end

    #def free_all_work_threads
    #
    #  work_threads.each { |t| t.raise(KillSignal) }
    #end

    def start

      @started_at = Time.now

      @thread =
        Thread.new do

          while @started_at do

            unschedule_jobs
            trigger_jobs unless @paused
            timeout_jobs

            sleep(@frequency)
          end
        end

      @thread[@thread_key] = true
      @thread[:rufus_scheduler] = self
      @thread[:name] = @opts[:thread_name] || "#{@thread_key}_scheduler"
    end

    def unschedule_jobs

      @jobs.delete_unscheduled
    end

    def trigger_jobs

      now = Time.now
      jobs_to_reschedule = []

      while job = @jobs.shift(now)

        reschedule = job.trigger(now)

        jobs_to_reschedule << job if reschedule
      end

      @jobs.concat(jobs_to_reschedule)
    end

    def timeout_jobs

      work_threads(:active).each do |t|

        job = t[:rufus_scheduler_job]
        to = t[:rufus_scheduler_timeout]

        next unless job && to
          # thread might just have become inactive (job -> nil)

        ts = t[:rufus_scheduler_time]
        to = to.is_a?(Time) ? to : ts + to

        next if to > Time.now

        t.raise(Rufus::Scheduler::TimeoutError)
      end
    end

    def do_schedule(job_type, t, callable, opts, return_job_instance, block)

      raise RuntimeError.new(
        'cannot schedule, scheduler is down or shutting down'
      ) if @started_at == nil

      callable, opts = nil, callable if callable.is_a?(Hash)
      return_job_instance ||= opts[:job]

      job_class =
        case job_type
          when :once
            tt = Rufus::Scheduler.parse(t)
            tt.is_a?(Time) ? AtJob : InJob
          when :every
            EveryJob
          when :interval
            IntervalJob
          when :cron
            CronJob
        end

      job = job_class.new(self, t, opts, block || callable)

      raise ArgumentError.new(
        "job frequency (#{job.frequency}) is higher than " +
        "scheduler frequency (#{@frequency})"
      ) if job.respond_to?(:frequency) && job.frequency < @frequency

      @jobs.push(job)

      return_job_instance ? job : job.job_id
    end

    #--
    # a thread-safe array for Jobs
    #
    # JRuby (Quartz-land), Rubinius?, ...
    #++

    class JobArray

      def initialize

        @mutex = Mutex.new
        @array = []
      end

      def concat(jobs)

        @mutex.synchronize { jobs.each { |j| do_push(j) } }

        self
      end

      def shift(now)

        @mutex.synchronize {
          nxt = @array.first
          return nil if nxt.nil? || nxt.next_time > now
          @array.shift
        }
      end

      def push(job)

        @mutex.synchronize { do_push(job) }

        self
      end

      def delete_unscheduled

        @mutex.synchronize { @array.delete_if { |j| j.unscheduled_at } }
      end

      def to_a

        @mutex.synchronize { @array.dup }
      end

      def [](job_id)

        @mutex.synchronize { @array.find { |j| j.job_id == job_id } }
      end

      protected

      def do_push(job)

        a = 0
        z = @array.length - 1

        i =
          loop do

            break a if z < 0

            break a if job.next_time <= @array[a].next_time
            break z + 1 if job.next_time >= @array[z].next_time

            m = (a + z) / 2

            if job.next_time < @array[m].next_time
              a += 1; z = m
            else
              a = m; z -= 1
            end
          end

        @array.insert(i, job)
      end
    end
  end
end

