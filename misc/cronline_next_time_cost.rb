
$:.unshift('lib')
require 'rufus/scheduler'

loop do

  print "> "
  s = gets

  cl = Rufus::Scheduler::CronLine.new(s)

  t = Time.now
  puts cl.next_time
  puts "took #{Time.now - t} secs"

  t = Time.now
  p cl.frequency
  puts "took #{Time.now - t} secs"
end

