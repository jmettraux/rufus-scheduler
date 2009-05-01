
$:.unshift('lib')

require 'rubygems'
require 'rufus/scheduler/em'

# scheduler


s = Rufus::Scheduler.start_new

puts Time.now.to_s

s.in('1s') do
  p [ :in, Time.now.to_s ]
  exit 0
end

s.join

