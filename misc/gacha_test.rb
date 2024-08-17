
#
# from @gacha
#
# in https://github.com/jmettraux/rufus-scheduler/issues/84
#

#
# Linux 3.2.0-4-amd64 #1 SMP Debian 3.2.46-1+deb7u1 x86_64 GNU/Linux
#
#
# * max work threads default to 28 (was 35)
#
# ruby 2.0.0p247 (2013-06-27 revision 41674) [x86_64-linux]
# dies ("Killed") after reaching 22 work threads
#
# ruby 1.9.3p392 (2013-02-22 revision 39386) [x86_64-linux]
# is fine, is pegged at 28 (was 35)
#
# jruby 1.7.4 (1.9.3p392) 2013-05-16 2390d3b on
#   OpenJDK 64-Bit Server VM 1.6.0_27-b27 [linux-amd64]
# dies ("Killed") after reaching 2 work threads
#
# ruby 1.8.7 (2012-10-12 patchlevel 371) [x86_64-linux]
# is fine, is pegged at 28 (was 35)
#
# ruby 2.0.0p195 (2013-05-14 revision 40734) [x86_64-linux
# dies ("Killed") after reaching 21 work threads
#
#
# * max work threads set at 7
#
# ruby 2.0.0p247 (2013-06-27 revision 41674) [x86_64-linux]
# is pegged at 7, but dies ("Killed") after a while (135 seconds)
#
# ruby 2.0.0p195 (2013-05-14 revision 40734) [x86_64-linux
# is pegged at 7, seems OK (stopped the test after 349 seconds)
#

puts "Ruby #{RUBY_VERSION}p#{RUBY_PATCHLEVEL}"


require 'rufus-scheduler'

#s = Rufus::Scheduler.new
s = Rufus::Scheduler.new(:max_work_threads => 7)

s.every '5s', :overlap => false do
  puts '.. 1st task started'
  numbers = (0..5000000).to_a.shuffle
  numbers.sort
  puts 'oo 1st task finished'
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
    :work_threads, s.work_threads.size,
    :active_work_threads, s.work_threads(:active).size
  ]
  sleep 1
end

#s.join

