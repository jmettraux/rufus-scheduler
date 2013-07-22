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

    require 'rufus/scheduler/cronline'

    VERSION = '3.0.0'

    attr_accessor :frequency
    attr_reader :thread
    attr_reader :mutexes

    def initialize(opts={})

      @started_at = nil
      @paused = false

      @jobs = JobArray.new

      @opts = opts
      @frequency = Rufus::Scheduler.parse(@opts[:frequency] || 0.300)
      @mutexes = {}

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

    # Shuts down the scheduler.
    #
    # By default simply stops the scheduler thread.
    # It accept an opt parameter. When set to :terminate, will terminate all
    # the jobs and then shut down the scheduler.
    #
    # The opt can all be set to :kill, in which case all the job threads are
    # killed and the scheduler is shut down.
    #
    def shutdown(opt=nil)

      if opt == :terminate
        terminate_all_jobs
      elsif opt == :kill
        jobs.each { |j| j.kill }
      end

      @started_at = nil
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

    def at(time, opts={}, &block)

      do_schedule(
        Rufus::Scheduler::AtJob, time, opts, opts[:job], block)
    end

    def schedule_at(time, opts={}, &block)

      do_schedule(
        Rufus::Scheduler::AtJob, time, opts, true, block)
    end

    def in(duration, opts={}, &block)

      do_schedule(
        Rufus::Scheduler::InJob, duration, opts, opts[:job], block)
    end

    def schedule_in(duration, opts={}, &block)

      do_schedule(
        Rufus::Scheduler::InJob, duration, opts, true, block)
    end

    def every(duration, opts={}, &block)

      do_schedule(
        Rufus::Scheduler::EveryJob, duration, opts, opts[:job], block)
    end

    def schedule_every(duration, opts={}, &block)

      do_schedule(
        Rufus::Scheduler::EveryJob, duration, opts, true, block)
    end

    def cron(cronline, opts={}, &block)

      do_schedule(
        Rufus::Scheduler::CronJob, cronline, opts, opts[:job], block)
    end

    def schedule_cron(cronline, opts={}, &block)

      do_schedule(
        Rufus::Scheduler::CronJob, cronline, opts, true, block)
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

      js = (@jobs.to_a + job_threads.collect { |t| t[thread_key][:job] }).uniq

      if opts[:running]
        js = js.select { |j| j.running? }
      else
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

    def cron_jobs(opts={})

      jobs(opts).select { |j| j.is_a?(Rufus::Scheduler::CronJob) }
    end

    #def find_by_tag(*tags)
    #  jobs(:tags => tags)
    #end

    def job(job_id)

      @jobs[job_id]
    end

    def job_threads

      Thread.list.select { |t| t[thread_key] }
    end

    def thread_key

      @thread_key ||= "rufus_scheduler_#{self.object_id}"
    end

    def running_jobs(opts={})

      jobs(opts.merge(:running => true))
    end

    def terminate_all_jobs

      jobs.each { |j| j.unschedule }

      while running_jobs.size > 0
        sleep 0.01
      end
    end

    protected

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

      @thread[:rufus_scheduler] = self
      @thread[:name] = @opts[:thread_name] || "#{thread_key}_scheduler"
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

      job_threads.each do |t|

        info = t[thread_key]
        to = info[:job].timeout

        next unless to

        now = Time.now.to_f
        ts = info[:timestamp]

        if to.is_a?(Time)
          next if to.to_f > now
        else
          next if ts + to < now
        end

        t.raise(Rufus::Scheduler::TimeoutError)
      end
    end

    def do_schedule(job_class, t, opts, return_job_instance, block)

      job = job_class.new(self, t, opts, block)
      @jobs.push(job)

      return_job_instance ? job : job.job_id
    end

    #--
    # job classes
    #++

    class Job

      attr_reader :id
      attr_reader :opts
      attr_reader :original
      attr_reader :scheduled_at
      attr_reader :last_time
      attr_reader :timeout
      attr_reader :unscheduled_at
      attr_reader :tags

      def initialize(scheduler, original, opts, block)

        @scheduler = scheduler
        @original = original
        @opts = opts
        @block = block

        @scheduled_at = Time.now
        @unscheduled_at = nil
        @last_time = nil
        @mutexes = {}

        @id = determine_id

        raise(
          ArgumentError,
          'missing block to schedule',
          caller[2..-1]
        ) unless @block

        @timeout =
          if to = @opts[:timeout]
            Rufus::Scheduler.parse(to)
          else
            nil
          end

        @tags = Array(opts[:tag] || opts[:tags]).collect { |t| t.to_s }

        # tidy up options

        if @opts[:allow_overlap] == false || @opts[:allow_overlapping] == false
          @opts[:overlap] = false
        end
        if m = @opts[:mutex]
          @opts[:mutex] = Array(m)
        end
      end

      alias job_id id

      def trigger(time)

        return if opts[:overlap] == false && running?

        if opts[:blocking]
          do_trigger(time)
        else
          Thread.new do
            (opts[:mutex] || []).reduce(
              lambda { do_trigger(time) }
            ) do |blk, m|
              lambda { mutex(m).synchronize { blk.call } }
            end.call
          end
        end

        false # do not reschedule
      end

      def unschedule

        @unscheduled_at = Time.now
      end

      def threads

        Thread.list.select { |t| t[thread_key] != nil }
      end

      def thread_values

        k = thread_key

        threads.collect { |t| t[k] }
      end

      # Kills all the threads this Job currently has going on.
      #
      def kill

        threads.each { |t| t.kill }
      end

      def running?

        threads.any?
      end

      # Returns the key used in the thread local vars to store info about
      # the job.
      #
      def thread_key

        "#{@scheduler.thread_key}_job_#{@id}"
      end

      protected

      def mutex(m)

        m.is_a?(Mutex) ? m : (@scheduler.mutexes[m.to_s] ||= Mutex.new)
      end

      def do_trigger(time)

        k = thread_key

        info ={ :job => self, :timestamp => time.to_f }
        Thread.current[k] = info
        Thread.current[@scheduler.thread_key] = info

        @last_time = time

        args = [ self, time ][0, @block.arity]
        @block.call(*args)

        Thread.current[k] = nil
        Thread.current[@scheduler.thread_key] = nil
      end
    end

    class OneTimeJob < Job

      attr_reader :time

      alias next_time time

      protected

      def determine_id

        [
          self.class.name.split(':').last.downcase[0..-4],
          @scheduled_at.to_f,
          @time.to_f,
          opts.hash.abs
        ].map(&:to_s).join('_')
      end
    end

    class AtJob < OneTimeJob

      def initialize(scheduler, time, opts, block)

        @time = Rufus::Scheduler.parse_at(time)

        super(scheduler, time, opts, block)
      end
    end

    class InJob < OneTimeJob

      def initialize(scheduler, duration, opts, block)

        super(scheduler, duration, opts, block)

        @time = @scheduled_at + Rufus::Scheduler.parse_in(duration)
      end
    end

    class RepeatJob < Job

      attr_reader :next_time
      attr_reader :paused_at

      attr_accessor :first_at
      attr_accessor :last_at
      attr_accessor :times

      def initialize(scheduler, duration, opts, block)

        super

        @paused_at = nil

        @times = opts[:times]

        raise ArgumentError.new(
          "cannot accept :times => #{@times.inspect}, not nil or an int"
        ) unless @times == nil || @times.is_a?(Fixnum)

        first = opts[:first] || opts[:first_at] || opts[:first_in] || 0
        f = first
        f = Rufus::Scheduler.parse(f) if f.is_a?(String)
        @first_at = f.is_a?(Numeric) ? Time.now + f : f

        raise ArgumentError.new(
          "cannot accept :first => #{first.inspect}, doesn't make sense"
        ) unless @first_at.is_a?(Time)

        last = opts[:last] || opts[:last_at] || opts[:last_in] || nil
        l = last
        l = Rufus::Scheduler.parse(l) if l.is_a?(String)
        @last_at = l.is_a?(Numeric) ? Time.now + l : l

        raise ArgumentError.new(
          "cannot accept :last => #{first.inspect}, doesn't make sense"
        ) unless @last_at == nil || @last_at.is_a?(Time)
      end

      def trigger(time)

        return true if @paused_at
        return true if time < @first_at

        return false if @last_at && time >= @last_at

        super

        return true unless @times
          # reschedule

        @times = @times - 1

        (@times > 0)
          # reschedule unless times reached 0
      end

      def pause

        @paused_at = Time.now
      end

      def resume

        @paused_at = nil
      end

      def paused?

        @paused_at != nil
      end
    end

    class EveryJob < RepeatJob

      attr_reader :frequency

      def initialize(scheduler, duration, opts, block)

        super(scheduler, duration, opts, block)

        @frequency = Rufus::Scheduler.parse_in(@original)
        @next_time = @scheduled_at + @frequency

        raise ArgumentError.new(
          "cannot schedule EveryJob with a frequency " +
          "of #{@frequency.inspect} (#{@original.inspect})"
        ) if @frequency <= 0
      end

      def trigger(time)

        reschedule = super

        @next_time =
          if time < @first_at
            time + @scheduler.frequency
              # force scheduler to consider us at next step
          else
            time + @frequency
              # rest until next occurence
          end

        reschedule
      end

      def determine_id

        [
          self.class.name.split(':').last.downcase[0..-4],
          @scheduled_at.to_f,
          opts.hash.abs
        ].map(&:to_s).join('_')
      end
    end

    class CronJob < RepeatJob

      def initialize(scheduler, cronline, opts, block)

        super(scheduler, cronline, opts, block)

        @cron_line = CronLine.new(cronline)
        @next_time = @cron_line.next_time
      end

      def trigger(time)

        reschedule = super

        @next_time = @cron_line.next_time(time)

        reschedule
      end

      def determine_id

        [
          self.class.name.split(':').last.downcase[0..-4],
          @scheduled_at.to_f,
          opts.hash.abs
        ].map(&:to_s).join('_')
      end
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

    #
    # This error is thrown when the :timeout attribute triggers
    #
    class TimeoutError < RuntimeError
    end

    #--
    # time and string methods
    #++

    def self.parse(o)

      opts = { :no_error => true }

      parse_in(o, opts) || # covers 'every' schedule strings
      parse_at(o, opts) ||
      parse_cron(o, opts) ||
      raise(ArgumentError.new("couldn't parse \"#{o}\""))
    end

    def self.parse_in(o, opts={})

      o.is_a?(String) ? parse_duration(o, opts) : o
    end

    TZ_REGEX = /\b((?:[a-zA-Z][a-zA-z0-9\-+]+)(?:\/[a-zA-Z0-9\-+]+)?)\b/

    def self.parse_at(o, opts={})

      return o if o.is_a?(Time)

      tz = nil
      s =
        o.to_s.gsub(TZ_REGEX) { |m|
          t = TZInfo::Timezone.get(m) rescue nil
          tz ||= t
          t ? '' : m
        }

      begin
        DateTime.parse(o)
      rescue
        raise ArgumentError, "no time information in #{o.inspect}"
      end if RUBY_VERSION < '1.9.0'

      t = Time.parse(s)

      t = tz.local_to_utc(t) if tz

      t

    rescue StandardError => se

      return nil if opts[:no_error]
      raise se
    end

    def self.parse_cron(o, opts)

      CronLine.new(o)

    rescue ArgumentError => ae

      return nil if opts[:no_error]
      raise ae
    end

    DURATIONS2M = [
      [ 'y', 365 * 24 * 3600 ],
      [ 'M', 30 * 24 * 3600 ],
      [ 'w', 7 * 24 * 3600 ],
      [ 'd', 24 * 3600 ],
      [ 'h', 3600 ],
      [ 'm', 60 ],
      [ 's', 1 ]
    ]
    DURATIONS2 = DURATIONS2M.dup
    DURATIONS2.delete_at(1)

    DURATIONS = DURATIONS2M.inject({}) { |r, (k, v)| r[k] = v; r }
    DURATION_LETTERS = DURATIONS.keys.join

    DU_KEYS = DURATIONS2M.collect { |k, v| k.to_sym }

    # Turns a string like '1m10s' into a float like '70.0', more formally,
    # turns a time duration expressed as a string into a Float instance
    # (millisecond count).
    #
    # w -> week
    # d -> day
    # h -> hour
    # m -> minute
    # s -> second
    # M -> month
    # y -> year
    # 'nada' -> millisecond
    #
    # Some examples:
    #
    #   Rufus::Scheduler.parse_duration_string "0.5"    # => 0.5
    #   Rufus::Scheduler.parse_duration_string "500"    # => 0.5
    #   Rufus::Scheduler.parse_duration_string "1000"   # => 1.0
    #   Rufus::Scheduler.parse_duration_string "1h"     # => 3600.0
    #   Rufus::Scheduler.parse_duration_string "1h10s"  # => 3610.0
    #   Rufus::Scheduler.parse_duration_string "1w2d"   # => 777600.0
    #
    # Negative time strings are OK (Thanks Danny Fullerton):
    #
    #   Rufus::Scheduler.parse_duration_string "-0.5"   # => -0.5
    #   Rufus::Scheduler.parse_duration_string "-1h"    # => -3600.0
    #
    def self.parse_duration(string, opts={})

      string = string.to_s

      return 0.0 if string == ''

      m = string.match(/^(-?)([\d\.#{DURATION_LETTERS}]+)$/)

      return nil if m.nil? && opts[:no_error]
      raise ArgumentError.new("cannot parse '#{string}'") if m.nil?

      mod = m[1] == '-' ? -1.0 : 1.0
      val = 0.0

      s = m[2]

      while s.length > 0
        m = nil
        if m = s.match(/^(\d+|\d+\.\d*|\d*\.\d+)([#{DURATION_LETTERS}])(.*)$/)
          val += m[1].to_f * DURATIONS[m[2]]
        elsif s.match(/^\d+$/)
          val += s.to_i
        elsif s.match(/^\d*\.\d*$/)
          val += s.to_f
        elsif opts[:no_error]
          return nil
        else
          raise ArgumentError.new(
            "cannot parse '#{string}' (especially '#{s}')"
          )
        end
        break unless m && m[3]
        s = m[3]
      end

      mod * val
    end

    # Turns a number of seconds into a a time string
    #
    #   Rufus.to_duration_string 0                    # => '0s'
    #   Rufus.to_duration_string 60                   # => '1m'
    #   Rufus.to_duration_string 3661                 # => '1h1m1s'
    #   Rufus.to_duration_string 7 * 24 * 3600        # => '1w'
    #   Rufus.to_duration_string 30 * 24 * 3600 + 1   # => "4w2d1s"
    #
    # It goes from seconds to the year. Months are not counted (as they
    # are of variable length). Weeks are counted.
    #
    # For 30 days months to be counted, the second parameter of this
    # method can be set to true.
    #
    #   Rufus.to_time_string 30 * 24 * 3600 + 1, true   # => "1M1s"
    #
    # (to_time_string is an alias for to_duration_string)
    #
    # If a Float value is passed, milliseconds will be displayed without
    # 'marker'
    #
    #   Rufus.to_duration_string 0.051                       # => "51"
    #   Rufus.to_duration_string 7.051                       # => "7s51"
    #   Rufus.to_duration_string 0.120 + 30 * 24 * 3600 + 1  # => "4w2d1s120"
    #
    # (this behaviour mirrors the one found for parse_time_string()).
    #
    # Options are :
    #
    # * :months, if set to true, months (M) of 30 days will be taken into
    #   account when building up the result
    # * :drop_seconds, if set to true, seconds and milliseconds will be trimmed
    #   from the result
    #
    def self.to_duration(seconds, options={})

      h = to_duration_hash(seconds, options)

      return (options[:drop_seconds] ? '0m' : '0s') if h.empty?

      s =
        DU_KEYS.inject('') { |r, key|
          count = h[key]
          count = nil if count == 0
          r << "#{count}#{key}" if count
          r
        }

      ms = h[:ms]
      s << ms.to_s if ms

      s
    end

    class << self
      alias to_duration_string to_duration
    end

    # Turns a number of seconds (integer or Float) into a hash like in :
    #
    #   Rufus.to_duration_hash 0.051
    #     # => { :ms => "51" }
    #   Rufus.to_duration_hash 7.051
    #     # => { :s => 7, :ms => "51" }
    #   Rufus.to_duration_hash 0.120 + 30 * 24 * 3600 + 1
    #     # => { :w => 4, :d => 2, :s => 1, :ms => "120" }
    #
    # This method is used by to_duration_string (to_time_string) behind
    # the scene.
    #
    # Options are :
    #
    # * :months, if set to true, months (M) of 30 days will be taken into
    #   account when building up the result
    # * :drop_seconds, if set to true, seconds and milliseconds will be trimmed
    #   from the result
    #
    def self.to_duration_hash(seconds, options={})

      h = {}

      if seconds.is_a?(Float)
        h[:ms] = (seconds % 1 * 1000).to_i
        seconds = seconds.to_i
      end

      if options[:drop_seconds]
        h.delete(:ms)
        seconds = (seconds - seconds % 60)
      end

      durations = options[:months] ? DURATIONS2M : DURATIONS2

      durations.each do |key, duration|

        count = seconds / duration
        seconds = seconds % duration

        h[key.to_sym] = count if count > 0
      end

      h
    end

    #--
    # misc
    #++

    # Produces the UTC string representation of a Time instance
    #
    # like "2009/11/23 11:11:50.947109 UTC"
    #
    def self.utc_to_s(t=Time.now)

      "#{t.utc.strftime('%Y-%m-%d %H:%M:%S')}.#{sprintf('%06d', t.usec)} UTC"
    end

    # Produces a hour/min/sec/milli string representation of Time instance
    #
    def self.h_to_s(t=Time.now)

      "#{t.strftime('%H:%M:%S')}.#{sprintf('%06d', t.usec)}"
    end

    # Debugging tools...
    #
    class D

      def self.h_to_s(t=Time.now); Rufus::Scheduler.h_to_s(t); end
    end
  end
end

