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


module Rufus

  class Scheduler

    #--
    # job classes
    #++

    class Job

      #
      # Used by Job#kill
      #
      class KillSignal < StandardError; end

      attr_reader :id
      attr_reader :opts
      attr_reader :original
      attr_reader :scheduled_at
      attr_reader :last_time
      attr_reader :unscheduled_at
      attr_reader :tags
      attr_reader :callable
      attr_reader :handler

      def initialize(scheduler, original, opts, block)

        @scheduler = scheduler
        @original = original
        @opts = opts

        @callable, @handler =
          if block.respond_to?(:arity)
            [ block, nil ]
          elsif block.respond_to?(:call)
            [ block.method(:call), block ]
          else
            nil
          end

        @scheduled_at = Time.now
        @unscheduled_at = nil
        @last_time = nil
        #@mutexes = {}
        #@pool_mutex = Mutex.new

        @locals = {}
        @local_mutex = Mutex.new

        @id = determine_id

        raise(
          ArgumentError,
          'missing block or callable to schedule',
          caller[2..-1]
        ) unless @callable

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

        return false if opts[:overlap] == false && running?

        r = callback(:pre, time)

        return false if r == false

        if opts[:blocking]
          do_trigger(time)
        else
          do_trigger_in_thread(time)
        end

        false # do not reschedule
      end

      def unschedule

        @unscheduled_at = Time.now
      end

      def threads

        Thread.list.select { |t| t[:rufus_scheduler_job] == self }
      end

      # Kills all the threads this Job currently has going on.
      #
      def kill

        threads.each { |t| t.raise(KillSignal) }
      end

      def running?

        threads.any?
      end

      def scheduled?

        @scheduler.scheduled?(self)
      end

      def []=(key, value)

        @local_mutex.synchronize { @locals[key] = value }
      end

      def [](key)

        @local_mutex.synchronize { @locals[key] }
      end

      def key?(key)

        @local_mutex.synchronize { @locals.key?(key) }
      end

      def keys

        @local_mutex.synchronize { @locals.keys }
      end

      #def hash
      #  self.object_id
      #end
      #def eql?(o)
      #  o.class == self.class && o.hash == self.hash
      #end
        #
        # might be necessary at some point

      protected

      def callback(position, time)

        name = position == :pre ? :on_pre_trigger : :on_post_trigger

        return unless @scheduler.respond_to?(name)

        args = @scheduler.method(name).arity < 2 ? [ self ] : [ self, time ]

        @scheduler.send(name, *args)
      end

      def compute_timeout

        if to = @opts[:timeout]
          Rufus::Scheduler.parse(to)
        else
          nil
        end
      end

      def mutex(m)

        m.is_a?(Mutex) ? m : (@scheduler.mutexes[m.to_s] ||= Mutex.new)
      end

      def do_trigger(time)

        t = Time.now
          # if there are mutexes, t might be really bigger than time

        Thread.current[:rufus_scheduler_job] = self
        Thread.current[:rufus_scheduler_time] = t
        Thread.current[:rufus_scheduler_timeout] = compute_timeout

        @last_time = t

        args = [ self, time ][0, @callable.arity]
        @callable.call(*args)

      rescue KillSignal

        # discard

      rescue StandardError => se

        @scheduler.on_error(self, se)

      ensure

        post_trigger(time)

        Thread.current[:rufus_scheduler_job] = nil
        Thread.current[:rufus_scheduler_time] = nil
        Thread.current[:rufus_scheduler_timeout] = nil
      end

      def post_trigger(time)

        callback(:post, time)
      end

      def start_work_thread

        thread =
          Thread.new do

            Thread.current[@scheduler.thread_key] = true
            Thread.current[:rufus_scheduler_job_thread] = true

            loop do

              job, time = @scheduler.work_queue.pop

              break if @scheduler.started_at == nil

              next if job.unscheduled_at

              begin

                (job.opts[:mutex] || []).reduce(
                  lambda { job.do_trigger(time) }
                ) do |b, m|
                  lambda { mutex(m).synchronize { b.call } }
                end.call

              rescue KillSignal

                # simply go on looping
              end
            end
          end

        thread[@scheduler.thread_key] = true
        thread[:rufus_scheduler_work_thread] = true
          #
          # same as above (in the thead block),
          # but since it has to be done as quickly as possible.
          # So, whoever is running first (scheduler thread vs job thread)
          # sets this information
      end

      def do_trigger_in_thread(time)

        #@pool_mutex.synchronize do

        count = @scheduler.work_threads.size
        #vacant = threads.select { |t| t[:rufus_scheduler_job] == nil }.size
        min = @scheduler.min_work_threads
        max = @scheduler.max_work_threads

        start_work_thread if count < max
        #end

        @scheduler.work_queue << [ self, time ]
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

      attr_reader :first_at
      attr_accessor :last_at
      attr_accessor :times

      def initialize(scheduler, duration, opts, block)

        super

        @paused_at = nil

        @times = opts[:times]

        raise ArgumentError.new(
          "cannot accept :times => #{@times.inspect}, not nil or an int"
        ) unless @times == nil || @times.is_a?(Fixnum)

        self.first_at =
          opts[:first] || opts[:first_at] || opts[:first_in] || 0
        self.last_at =
          opts[:last] || opts[:last_at] || opts[:last_in]
      end

      def first_at=(first)

        @first_at = Rufus::Scheduler.parse_to_time(first)
      end

      def last_at=(last)

        @last_at = last ? Rufus::Scheduler.parse_to_time(last) : nil
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

      def determine_id

        [
          self.class.name.split(':').last.downcase[0..-4],
          @scheduled_at.to_f,
          opts.hash.abs
        ].map(&:to_s).join('_')
      end
    end

    class EveryJob < RepeatJob

      attr_reader :frequency

      def initialize(scheduler, duration, opts, block)

        super(scheduler, duration, opts, block)

        @frequency = Rufus::Scheduler.parse_in(@original)
        @next_time = @scheduled_at + @frequency

        raise ArgumentError.new(
          "cannot schedule #{self.class} with a frequency " +
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
    end

    class IntervalJob < RepeatJob

      attr_reader :interval

      def initialize(scheduler, interval, opts, block)

        super(scheduler, interval, opts, block)

        @interval = Rufus::Scheduler.parse_in(@original)
        @next_time = @scheduled_at + @interval

        raise ArgumentError.new(
          "cannot schedule #{self.class} with an interval " +
          "of #{@interval.inspect} (#{@original.inspect})"
        ) if @interval <= 0
      end

      def trigger(time)

        super

        false
      end

      def post_trigger(time)

        super

        @next_time = Time.now + @interval
        @scheduler.send(:reschedule, self)
      end
    end

    class CronJob < RepeatJob

      def initialize(scheduler, cronline, opts, block)

        super(scheduler, cronline, opts, block)

        @cron_line = CronLine.new(cronline)
        @next_time = @cron_line.next_time
      end

      def frequency

        @cron_line.frequency
      end

      def trigger(time)

        reschedule = super

        @next_time = @cron_line.next_time(time)

        reschedule
      end
    end
  end
end

