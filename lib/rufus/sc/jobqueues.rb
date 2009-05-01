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


require 'thread'


module Rufus
module Scheduler

  #
  # Tracking at/in/every jobs.
  #
  # In order of trigger time.
  #
  class JobQueue

    # Mapping :at|:in|:every to their respective job classes.
    #
    JOB_TYPES = {
      :at => Rufus::Scheduler::AtJob,
      :in => Rufus::Scheduler::InJob,
      :every => Rufus::Scheduler::EveryJob
    }

    def initialize

      @mutex = Mutex.new
      @jobs = []
    end

    # Returns the next job to trigger. Returns nil if none eligible.
    #
    def job_to_trigger

      @mutex.synchronize do
        if @jobs.size > 0 && Time.now.to_f >= @jobs.first.at
          @jobs.shift
        else
          nil
        end
      end
    end

    # Adds this job to the map.
    #
    def << (job)

      @mutex.synchronize do
        delete(job.job_id)
        @jobs << job
        @jobs.sort! { |j0, j1| j0.at <=> j1.at }
      end
    end

    # Removes a job (given its id). Returns nil if the job was not found.
    #
    def unschedule (job_id)

      @mutex.synchronize { delete(job_id) }
    end

    # Returns a mapping job_id => job
    #
    def to_h

      @jobs.inject({}) { |h, j| h[j.job_id] = j; h }
    end

    # Returns a list of jobs of the given type (:at|:in|:every)
    #
    def select (type)

      type = JOB_TYPES[type]
      @jobs.select { |j| j.is_a?(type) }
    end

    def size

      @jobs.size
    end

    protected

    def delete (job_id)
      j = @jobs.find { |j| j.job_id == job_id }
      @jobs.delete(j) if j
      j
    end
  end

  #
  # Tracking cron jobs.
  #
  # (mostly synchronizing access to the map of cron jobs)
  #
  class CronJobQueue

    def initialize

      @mutex = Mutex.new
      @jobs = {}
    end

    def unschedule (job_id)

      @mutex.synchronize { @jobs.delete(job_id) }
    end

    def trigger_matching_jobs (now)

      js = @mutex.synchronize { @jobs.values }
        # maybe this sync is a bit paranoid

      js.each { |job| job.trigger_if_matches(now) }
    end

    def << (job)

      @mutex.synchronize { @jobs[job.job_id] = job }
    end

    def size

      @jobs.size
    end

    def to_h

      @jobs.dup
    end
  end

end
end

