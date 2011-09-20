#--
# Copyright (c) 2006-2010, John Mettraux, jmettraux@gmail.com
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


require 'rufus/sc/scheduler'
require 'rufus/exception_handlers/default'


module Rufus::Scheduler

  # A quick way to get a scheduler up an running
  #
  #   require 'rubygems'
  #   s = Rufus::Scheduler.start_new
  #
  # If EventMachine is present and running will create an EmScheduler, else
  # it will create a PlainScheduler instance.
  #
  def self.start_new(opts={})
    if defined?(EM) and EM.reactor_running?
      EmScheduler.start_new(opts)
    else
      PlainScheduler.start_new(opts)
    end
  end

  # Returns true if the given string seems to be a cron string.
  #
  def self.is_cron_string(s)

    s.match(/.+ .+ .+ .+ .+/) # well...
  end
end

