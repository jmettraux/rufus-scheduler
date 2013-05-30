
#
# Specifying rufus-scheduler
#
# Fri Mar 20 22:53:33 JST 2009
#

$:.unshift(File.expand_path('../../lib', __FILE__))

require 'rubygems'
require 'fileutils'


Thread.abort_on_exception = true


#$:.unshift(File.expand_path('~/tmp/bacon/lib')) # my own bacon for a while
#require 'bacon'
#puts
#Bacon.summary_on_exit


#
# rufus/scheduler/em

# EM or plain ?

$plain = ! ENV['EVENTMACHINE']

require 'rufus/scheduler'

if ( ! $plain)

  require 'eventmachine'

  unless (EM.reactor_running?)

    Thread.new { EM.run { } }

    sleep 0.200
    while (not EM.reactor_running?)
      Thread.pass
    end
      #
      # all this waiting, especially for the JRuby eventmachine, which seems
      # rather 'diesel'

  end
end

SCHEDULER_CLASS = $plain ?
  Rufus::Scheduler::PlainScheduler :
  Rufus::Scheduler::EmScheduler

#
# helper methods

def start_scheduler(opts={})
  SCHEDULER_CLASS.start_new(opts)
end

def stop_scheduler(s)
  #s.stop(:stop_em => true)
  #sleep 0.200 # give time to the EM to stop
  s.stop
  sleep 0.200
end

def wait_next_tick
  #if defined?(EM)
  #  t = Thread.current
  #  EM.next_tick { t.wakeup }
  #  Thread.stop
  #else
  sleep 0.500
  #end
end

def local(*args)
  Time.local(*args)
end
alias lo local

def utc(*args)
  Time.utc(*args)
end

