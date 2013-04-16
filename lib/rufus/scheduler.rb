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


module Rufus

  class Scheduler

    require 'rufus/scheduler/timezone'
    require 'rufus/scheduler/cronline'

    VERSION = '3.0.0'

    attr_accessor :frequency

    def initialize(opts={})

      @started_at = nil

      @schedule_queue = Queue.new
        # using a queue so that schedules/unschedules return immediately
        # (they don't wait for any mutex shared with the main loop)

      @jobs = JobArray.new

      @opts = opts
      @frequency = @opts[:frequency] || 0.300

      start
    end

    def shutdown

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

    #--
    # scheduling methods
    #++

    def at(time, opts={}, &block)

      job = schedule_at(time, opts, &block)

      opts[:job] ? job : job.id
    end

    def schedule_at(time, opts={}, &block)

      do_schedule(Rufus::Scheduler::AtJob, time, opts, block)
    end

    def in(duration, opts={}, &block)

      job = schedule_in(duration, opts, &block)

      opts[:job] ? job : job.id
    end

    def schedule_in(duration, opts={}, &block)

      do_schedule(Rufus::Scheduler::InJob, duration, opts, block)
    end

    def every(duration, opts={}, &block)

      job = schedule_every(duration, opts, &block)

      opts[:job] ? job : job.id
    end

    def schedule_every(duration, opts={}, &block)

      do_schedule(Rufus::Scheduler::EveryJob, duration, opts, block)
    end

    def unschedule(job_or_job_id)

      @schedule_queue << [ false, job_or_job_id ]
    end

    #--
    # jobs methods
    #++

    def jobs

      @jobs.to_a
    end

    def at_jobs;    jobs.select { |j| j.is_a?(Rufus::Scheduler::AtJob) }; end
    def in_jobs;    jobs.select { |j| j.is_a?(Rufus::Scheduler::InJob) }; end
    def every_jobs; jobs.select { |j| j.is_a?(Rufus::Scheduler::EveryJob) }; end
    def cron_jobs;  jobs.select { |j| j.is_a?(Rufus::Scheduler::CronJob) }; end

    protected

    def start

      @started_at = Time.now

      @thread =
        Thread.new do

          while @started_at do

            schedule_jobs
            trigger_jobs

            sleep(@frequency)
          end
        end

      @thread[:rufus_scheduler] =
        self
      @thread[:name] =
        @opts[:thread_name] || "rufus_scheduler_#{self.object_id}"
    end

    def schedule_jobs

      return if @schedule_queue.empty?

      while @schedule_queue.size > 0

        schedule, job = @schedule_queue.pop

        @jobs.send(schedule ? :push : :delete, job)
      end
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

    def do_schedule(job_class, t, opts, block)

      job = job_class.new(self, t, opts, block)

      @schedule_queue << [ true, job ]

      job
    end

    #--
    # job classes
    #++

    class Job

      attr_reader :id
      attr_reader :opts
      attr_reader :original
      attr_reader :scheduled_at

      def initialize(scheduler, original, opts, block)

        @scheduler = scheduler
        @original = original
        @opts = opts
        @block = block

        @scheduled_at = Time.now

        @id = determine_id

        raise(
          ArgumentError,
          'missing block to schedule',
          caller[2..-1]
        ) unless @block
      end

      alias job_id id

      def trigger(time)

        @block.call

        false # do not reschedule
      end

      def unschedule

        @scheduler.unschedule(self)
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

      def trigger(time)

        super

        true # do reschedule
      end
    end

    class EveryJob < RepeatJob

      attr_reader :next_time

      def initialize(scheduler, duration, opts, block)

        super(scheduler, duration, opts, block)

        @frequency = Rufus::Scheduler.parse_in(@original)
        @next_time = @scheduled_at + @frequency
      end

      def trigger(time)

        super

        @next_time = Time.now + @frequency

        true # do reschedule
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

      def delete(job_or_job_id)

        @mutex.synchronize {

          job_id = job_or_job_id
          job_id = job_id.job_id if job_id.is_a?(Rufus::Scheduler::Job)

          @array.delete_if { |j| j.job_id == job_id }
        }

        self
      end

      def to_a

        @mutex.synchronize { @array.dup }
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

    #--
    # time and string methods
    #++

    def self.parse(o)

      parse_in(o) || parse_at(o)
    end

    def self.parse_in(o)

      o.is_a?(String) ? parse_duration(o, :no_error => true) : o
    end

    def self.parse_at(o)

      return o if o.is_a?(Time)

      begin
        DateTime.parse(o)
      rescue
        raise ArgumentError, "no time information in #{o.inspect}"
      end if RUBY_VERSION < '1.9.0'

      Time.parse(o)
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
          val += s.to_i / 1000.0
        elsif s.match(/^\d*\.\d*$/)
          val += s.to_f
        elsif opts[:no_error]
          return nil
        else
          raise ArgumentError.new("cannot parse '#{string}' (especially '#{s}')")
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

