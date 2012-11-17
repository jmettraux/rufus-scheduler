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

require 'thread'


module Rufus

  class Scheduler

    VERSION = '3.0.0'

    def initialize(opts={})

      @started_at = nil

      @schedule_queue = Queue.new
        # using a queue so that schedules/unschedules return immediately
        # (they don't wait for any mutex shared with the main loop)

      @jobs = JobArray.new

      @frequency = opts[:frequency] || 0.300

      start
    end

    def shutdown

      @started_at = nil
    end

    def uptime

      @started_at ? Time.now - @started_at : nil
    end

    #--
    # scheduling methods
    #++

    def at(time, opts={}, &block)

      schedule_at(time, opts, &block).id
    end

    def schedule_at(time, opts={}, &block)

      job = Rufus::Scheduler::AtJob.new(self, time, opts, block)

      @schedule_queue << [ true, job ]

      job
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

    #--
    # job classes
    #++

    class Job

      attr_reader :id
      attr_reader :opts

      def initialize(scheduler, id, opts, block)

        @scheduler = scheduler
        @id = id
        @opts = opts
        @block = block

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
    end

    class AtJob < Job

      attr_reader :time

      def initialize(scheduler, time, opts, block)

        @time = time

        super(
          scheduler,
          "at_#{Time.now.to_f}_#{time.to_f}_#{opts.hash}", # TODO change me
          opts,
          block)
      end

      alias next_time time
    end

    class InJob < AtJob
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
  end
end

