#--
# Copyright (c) 2006-2012, John Mettraux, jmettraux@gmail.com
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

require 'time'
require 'thread'


module Rufus

  class Scheduler

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

    def unschedule(job_or_job_id)

      @schedule_queue << [ false, job_or_job_id ]
    end

    #--
    # jobs methods
    #++

    def jobs

      @jobs.to_a
    end

    def at_jobs

      jobs.select { |j| j.is_a?(Rufus::Scheduler::AtJob) }
    end

    def in_jobs

      jobs.select { |j| j.is_a?(Rufus::Scheduler::InJob) }
    end

    def every_jobs

      jobs.select { |j| j.is_a?(Rufus::Scheduler::EveryJob) }
    end

    def cron_jobs

      jobs.select { |j| j.is_a?(Rufus::Scheduler::CronJob) }
    end

    protected

    def start

      @started_at = Time.now

      @thread = Thread.new do

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
      jobs_to_remove = []

      @jobs.each do |job|

        break if job.next_time > now

        remove = job.trigger(now)
        jobs_to_remove << job if remove
      end

      @jobs = @jobs - jobs_to_remove
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

      def initialize(scheduler, original, opts, block)

        @scheduler = scheduler
        @original = original
        @opts = opts
        @block = block

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

        true
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
          Time.now.to_f,
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

        @time = Time.now + Rufus::Scheduler.parse_in(duration)

        super(scheduler, duration, opts, block)
      end
    end

    class RepeatJob < Job

      def trigger(time)

        super

        false # do not remove job after it got triggered
      end
    end

    class EveryJob < RepeatJob
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
        @shuffled = false
      end

      def each(&block)

        @mutex.synchronize {

          @array.sort_by!(&:next_time) if @shuffled
          @shuffled = false

          @array.each(&block)
        }
      end

      def -(other)

        @mutex.synchronize { @array = @array - other }

        self
      end

      def push(job)

        @mutex.synchronize {

          @shuffled = true
          @array << job
        }

        self
      end

      def delete(job_or_job_id)

        @mutex.synchronize {

          if job_or_job_id.is_a?(Rufus::Scheduler::Job)
            @array.delete(job_or_job_id)
          else
            @array.delete_if { |j| j.job_id == job_or_job_id }
          end
        }

        # no need to set the @shuffled flag

        self
      end

      def to_a

        @mutex.synchronize { @array.dup }
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

      o.is_a?(Time) ? o : Time.parse(o)
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
    #DURATIONS2 = DURATIONS2M.dup
    #DURATIONS2.delete_at(1)

    DURATIONS = DURATIONS2M.inject({}) { |r, (k, v)| r[k] = v; r }
    DURATION_LETTERS = DURATIONS.keys.join

    #DU_KEYS = DURATIONS2M.collect { |k, v| k.to_sym }

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
  end
end

