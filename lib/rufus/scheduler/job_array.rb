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

    #
    # The array rufus-scheduler uses to keep jobs in order (next to trigger
    # first).
    #
    class JobArray

      def initialize

        @mutex = Mutex.new
        @array = []
      end

      def concat(jobs)

        @mutex.synchronize { do_concat(jobs) }

        self
      end

      def push(job)

        @mutex.synchronize { do_concat([ job ]) }

        self
      end

      def shift(now)

        @mutex.synchronize {
          nxt = @array.first
          return nil if nxt.nil? || nxt.next_time > now
          @array.shift
        }
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

      def do_concat(jobs)

        @array = @array.concat(jobs).uniq.sort_by(&:next_time)
      end
    end
  end
end

