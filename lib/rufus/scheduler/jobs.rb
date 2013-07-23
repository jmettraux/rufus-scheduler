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

      attr_reader :id
      attr_reader :opts
      attr_reader :original
      attr_reader :scheduled_at
      attr_reader :last_time
      attr_reader :timeout
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
        @mutexes = {}

        @id = determine_id

        raise(
          ArgumentError,
          'missing block or callable to schedule',
          caller[2..-1]
        ) unless @callable

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

        args = [ self, time ][0, @callable.arity]
        @callable.call(*args)

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

