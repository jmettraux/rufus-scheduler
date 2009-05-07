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


module Rufus
module Scheduler

  #
  # The base class for all types of jobs.
  #
  class Job

    # A reference to the scheduler owning this job
    #
    attr_reader :scheduler

    # The initial, raw, scheduling info (at / in / every / cron)
    #
    attr_reader :t

    # When the job is actually running, this attribute will hold the
    # thread in which the job is running.
    # Can be used to determine if a job is actually running.
    #
    attr_reader :job_thread

    # The job parameters (passed via the schedule method)
    #
    attr_reader :params

    # The block to call when triggering
    #
    attr_reader :block

    # Last time the job executed
    # (for an {At|In}Job, it will mean 'not executed' if nil or when
    # it got executed if set)
    #
    # (
    # Last time job got triggered (most useful with EveryJob, but can be
    # useful with remaining instances of At/InJob (are they done ?))
    # )
    #
    attr_reader :last

    # The identifier for this job.
    #
    attr_reader :job_id


    # Instantiating the job.
    #
    def initialize (scheduler, t, params, &block)

      @scheduler = scheduler
      @t = t
      @params = params
      @block = block || params[:schedulable]

      raise ArgumentError.new(
        'no block or :schedulable passed, nothing to schedule'
      ) unless @block

      @params[:tags] = Array(@params[:tags])

      @job_id = params[:job_id] || "#{self.class.name}_#{self.object_id.to_s}"

      determine_at
    end

    # Returns the list of tags attached to the job.
    #
    def tags

      @params[:tags]
    end

    # Sets the list of tags attached to the job (Usually they are set
    # via the schedule every/at/in/cron method).
    #
    def tags= (tags)

      @params[:tags] = Array(tags)
    end

    # Generally returns the string/float/integer used to schedule the job
    # (seconds, time string, date string)
    #
    def schedule_info

      @t
    end

    # Triggers the job.
    #
    def trigger (t=Time.now)

      @last = t

      @scheduler.send(:trigger_job, @params[:blocking]) do
        #
        # Note that #trigger_job is protected, hence the #send
        # (Only jobs know about this method of the scheduler)

        @job_thread = Thread.current

        begin

          #args = prepare_args
          #@block.call(*args)

          #@block.call(self)

          @block.respond_to?(:call) ?
            @block.call(self) : @block.trigger(@params)

          @job_thread = nil

        rescue Exception => e

          @scheduler.handle_exception(self, e)
        end
      end

      # note that add_job and add_cron_job ensured that :blocking is
      # not used along :timeout

      if to = @params[:timeout]

        @scheduler.in(to, :tags => 'timeout') do

          # at this point, @job_thread might be set

          @job_thread.raise(Rufus::Scheduler::TimeOutError) \
            if @job_thread and @job_thread.alive?
        end
      end
    end

    # Unschedules this job.
    #
    def unschedule

      @scheduler.unschedule(self.job_id)
    end

    #--
    #protected
    #
    # Prepare the args given the triggered block arity.
    #
    #def prepare_args
    #  if @scheduler.options[:onezero_block_arity]
    #    case @block.arity
    #      when 0 then []
    #      when 1 then [ @params ]
    #      when 2 then [ @job_id, @params ]
    #      #else [ @job_id, schedule_info, @params ]
    #      else [ @job_id, self, @params ]
    #    end
    #  else
    #    [ self ]
    #  end
    #end
    #++
  end

  #
  # The base class of at/in/every jobs.
  #
  class SimpleJob < Job

    # When the job is supposed to trigger
    #
    attr_reader :at

    attr_reader :last

    def determine_at

      @at = Rufus.at_to_f(@t)
    end

    # Returns the next time (or the unique time) this job is meant to trigger
    #
    def next_time

      Time.at(@at)
    end
  end

  #
  # Job that occurs once, in a certain amount of time.
  #
  class InJob < SimpleJob

    protected

    def determine_at

      iin = @t.is_a?(Fixnum) || @t.is_a?(Float) ?
        @t : Rufus.parse_duration_string(@t)

      @at = (Time.now + iin).to_f
    end
  end

  #
  # Job that occurs once, at a certain point in time.
  #
  class AtJob < SimpleJob
  end

  #
  # Recurring job with a certain frequency.
  #
  class EveryJob < SimpleJob

    # The frequency, in seconds, of this EveryJob
    #
    attr_reader :frequency

    def initialize (scheduler, t, params, &block)
      super
      determine_frequency
      determine_at
    end

    # Triggers the job (and reschedules it).
    #
    def trigger

      schedule_next

      super

      #unschedule if @params[:dont_reschedule]
        # obsolete
    end

    protected

    def determine_frequency

      @frequency = @t.is_a?(Fixnum) || @t.is_a?(Float) ?
        @t : Rufus.parse_duration_string(@t)
    end

    def determine_at

      return unless @frequency

      @last = @at
        # the first time, @last will be nil

      @at = if @last
        @last + @frequency
      else
        if fi = @params[:first_in]
          Time.now.to_f + Rufus.duration_to_f(fi)
        elsif fa = @params[:first_at]
          Rufus.at_to_f(fa)
        else
          Time.now.to_f + @frequency
        end
      end
    end

    # It's an every job, have to schedule next time it occurs...
    #
    def schedule_next

      determine_at

      @scheduler.send(:add_job, self)
    end
  end

  #
  # Recurring job, cron style.
  #
  class CronJob < Job

    # The CronLine instance, it holds all the info about the cron schedule
    #
    attr_reader :cron_line

    # The job parameters (passed via the schedule method)
    #
    attr_reader :params

    # The block to call when triggering
    #
    attr_reader :block

    # Creates a new CronJob instance.
    #
    def initialize (scheduler, cron_string, params, &block)

      super

      @cron_line = case @t

        when String then CronLine.new(@t)
        when CronLine then @t

        else raise "cannot initialize a CronJob out of #{@t.inspect}"
      end
    end

    def trigger_if_matches (time)

      trigger(time) if @cron_line.matches?(time)
    end

    # Returns the next time this job is meant to trigger
    #
    def next_time (from=Time.now)

      @cron_line.next_time(from)
    end

    protected

    def determine_at
      # empty
    end
  end

end
end

