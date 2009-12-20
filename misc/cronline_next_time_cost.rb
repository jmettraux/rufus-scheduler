
$:.unshift('lib')
require 'rufus/scheduler'

loop do

  print "> "
  s = gets

  t = Time.now
  puts Rufus::CronLine.new(s).next_time
  puts "took #{Time.now - t} secs"
end

