
#
# Specifying rufus-scheduler-em
#
# Fri Mar 20 22:53:33 JST 2009
#


#
# bacon

$:.unshift(File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib')))

require 'rubygems'
require 'fileutils'


$:.unshift(File.expand_path('~/tmp/bacon/lib')) # my own bacon for a while

require 'bacon'

puts

Bacon.summary_on_exit


#
# rufus/scheduler/em

# EM or plain ?

$plain = ARGV.include?('--plain')

require 'rufus/scheduler/em'

if ( ! $plain)

  require 'eventmachine'

  unless( ! EM.reactor_running?)
    Thread.new { EM.run { } }
    sleep 0.200
    #p [ :reactor_running?, EM.reactor_running? ]
  end
end

SCHEDULER_CLASS = $plain ?
  Rufus::Scem::PlainScheduler : Rufus::Scem::EmScheduler

#
# helper methods

def start_scheduler
  SCHEDULER_CLASS.start_new
end

def stop_scheduler (s)
  #s.stop(:stop_em => true)
  #sleep 0.200 # give time to the EM to stop
  s.stop
  sleep 0.200
end

def wait_next_tick
  if defined?(EM)
    t = Thread.current
    EM.next_tick { t.wakeup }
    Thread.stop
  else
    sleep 0.500
  end
end

