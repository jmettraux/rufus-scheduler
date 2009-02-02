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

module Rufus

  JOB_ID_LOCK = Mutex.new

  #
  # The parent class for scheduled jobs.
  #
  class Job

    @@last_given_id = 0
      #
      # as a scheduler is fully transient, no need to
      # have persistent ids, a simple counter is sufficient

    #
    # The identifier for the job
    #
    attr_accessor :job_id

    #
    # An array of tags
    #
    attr_accessor :tags

    #
    # The block to execute at trigger time
    #
    attr_accessor :block

    #
    # A reference to the scheduler
    #
    attr_reader :scheduler

    #
    # Keeping a copy of the initialization params of the job.
    #
    attr_reader :params

    #
    # if the job is currently executing, this field points to
    # the 'trigger thread'
    #
    attr_reader :trigger_thread


    def initialize (scheduler, job_id, params, &block)

      @scheduler = scheduler
      @block = block

      if job_id
        @job_id = job_id
      else
        JOB_ID_LOCK.synchronize do
          @job_id = @@last_given_id
          @@last_given_id = @job_id + 1
        end
      end

      @params = params

      #@tags = Array(tags).collect { |tag| tag.to_s }
        # making sure we have an array of String tags

      @tags = Array(params[:tags])
        # any tag is OK
    end

    #
    # Returns true if this job sports the given tag
    #
    def has_tag? (tag)

      @tags.include?(tag)
    end

    #
    # Removes (cancels) this job from its scheduler.
    #
    def unschedule

      @scheduler.unschedule(@job_id)
    end

    #
    # Triggers the job (in a dedicated thread).
    #
    def trigger

      t = Thread.new do

        @trigger_thread = Thread.current
          # keeping track of the thread

        begin

          do_trigger

        rescue Exception => e

          @scheduler.send(:log_exception, e)
        end

        #@trigger_thread = nil if @trigger_thread == Thread.current
        @trigger_thread = nil
          # overlapping executions, what to do ?
      end

      if t.alive? and (to = @params[:timeout])
        @scheduler.in(to, :tags => 'timeout') do
          @trigger_thread.raise(Rufus::TimeOutError) if t.alive?
        end
      end
    end

    def call_block

      args = case @block.arity
        when 0 then []
        when 1 then [ @params ]
        when 2 then [ @job_id, @params ]
        else [ @job_id, schedule_info, @params ]
      end

      @block.call(*args)
    end
  end

  #
  # An 'at' job.
  #
  class AtJob < Job

    #
    # The float representation (Time.to_f) of the time at which
    # the job should be triggered.
    #
    attr_accessor :at


    def initialize (scheduler, at, at_id, params, &block)

      super(scheduler, at_id, params, &block)
      @at = at
    end

    #
    # Returns the Time instance at which this job is scheduled.
    #
    def schedule_info

      Time.at(@at)
    end

    #
    # next_time is last_time (except for EveryJob instances). Returns
    # a Time instance.
    #
    def next_time

      schedule_info
    end

    protected

    #
    # Triggers the job (calls the block)
    #
    def do_trigger

      call_block

      @scheduler.instance_variable_get(:@non_cron_jobs).delete(@job_id)
    end
  end

  #
  # An 'every' job is simply an extension of an 'at' job.
  #
  class EveryJob < AtJob

    #
    # Returns the frequency string used to schedule this EveryJob,
    # like for example "3d" or "1M10d3h".
    #
    def schedule_info

      @params[:every]
    end

    protected

    #
    # triggers the job, then reschedules it if necessary
    #
    def do_trigger

      hit_exception = false

      begin

        call_block

      rescue Exception => e

        @scheduler.send(:log_exception, e)

        hit_exception = true
      end

      if \
        @scheduler.instance_variable_get(:@exit_when_no_more_jobs) or
        (@params[:dont_reschedule] == true) or
        (hit_exception and @params[:try_again] == false)

        @scheduler.instance_variable_get(:@non_cron_jobs).delete(job_id)
          # maybe it'd be better to wipe that reference from here anyway...

        return
      end

      #
      # ok, reschedule ...

      params[:job] = self

      @at = @at + Rufus.duration_to_f(params[:every])

      @scheduler.send(:do_schedule_at, @at, params)
    end
  end

  #
  # A cron job.
  #
  class CronJob < Job

    #
    # The CronLine instance representing the times at which
    # the cron job has to be triggered.
    #
    attr_accessor :cron_line

    def initialize (scheduler, cron_id, line, params, &block)

      super(scheduler, cron_id, params, &block)

      if line.is_a?(String)

        @cron_line = CronLine.new(line)

      elsif line.is_a?(CronLine)

        @cron_line = line

      else

        raise(
          "Cannot initialize a CronJob " +
          "with a param of class #{line.class}")
      end
    end

    #
    # This is the method called by the scheduler to determine if it
    # has to fire this CronJob instance.
    #
    def matches? (time)
    #def matches? (time, precision)

      #@cron_line.matches?(time, precision)
      @cron_line.matches?(time)
    end

    #
    # Returns the original cron tab string used to schedule this
    # Job. Like for example "60/3 * * * Sun".
    #
    def schedule_info

      @cron_line.original
    end

    #
    # Returns a Time instance : the next time this cron job is
    # supposed to "fire".
    #
    # 'from' is used to specify the starting point for determining
    # what will be the next time. Defaults to now.
    #
    def next_time (from=Time.now)

      @cron_line.next_time(from)
    end

    protected

    #
    # As the name implies.
    #
    def do_trigger

      call_block
    end
  end

end

