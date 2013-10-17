
#
# from @gacha
#
# in https://github.com/jmettraux/rufus-scheduler/issues/84
#

#
# Linux 3.2.0-4-amd64 #1 SMP Debian 3.2.46-1+deb7u1 x86_64 GNU/Linux
# ruby 2.0.0p247 (2013-06-27 revision 41674) [x86_64-linux]
# dies ("Killed") after reaching 22 work threads (max is the 35 default)
#
# ruby 1.9.3p392 (2013-02-22 revision 39386) [x86_64-linux]
# is fine, is pegged at 35
#
# jruby 1.7.4 (1.9.3p392) 2013-05-16 2390d3b on
#   OpenJDK 64-Bit Server VM 1.6.0_27-b27 [linux-amd64]
# dies ("Killed") after reaching 2 work threads
#
# ruby 1.8.7 (2012-10-12 patchlevel 371) [x86_64-linux]
# is fine, is pegged at 35
#

puts "Ruby #{RUBY_VERSION}p#{RUBY_PATCHLEVEL}"


require 'rufus-scheduler'

s = Rufus::Scheduler.new
#s = Rufus::Scheduler.new(:max_work_threads => 7)

s.every '5s', :overlap => false do
  puts '.. 1st task started'
  numbers = (0..5000000).to_a.shuffle
  numbers.sort
  puts 'oo 1nd task finished'
end

s.every '7s', :overlap => false do
  puts '.. 2nd task started'
  numbers = (0..5000000).to_a.shuffle
  numbers.sort
  puts 'oo 2nd task finished'
end


start = Time.now
loop do
  p [
    :elapsed, (Time.now - start).to_i,
    :threads, Thread.list.size,
    :work_threads, s.work_threads.size
  ]
  sleep 1
end

#s.join

