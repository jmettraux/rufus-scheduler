#!/usr/bin/env ruby
#
# six_field_cronline_test.rb
#
# Demonstrates an odd behavior with six-field cronlines.  We compare
# two schedules which ought to be identical:
#
#   each: 10s
#   cron: */10 * * * * *
#
# When we run this with rufus-scheduler 3.1.3, we get something like:
#
#   $ misc/six_field_cronline_test.rb
#     0.000: misc/six_field_cronline_test.rb: using rufus-scheduler 3.1.3
#     5.147: cron: '*/10 * * * * *'
#    10.296: every: 10s
#    15.142: cron: '*/10 * * * * *'
#    20.597: every: 10s
#    25.128: cron: '*/10 * * * * *'
#    30.887: every: 10s
#    35.122: cron: '*/10 * * * * *'
#    41.185: every: 10s
#    51.470: every: 10s
#    61.756: every: 10s
#    72.051: every: 10s
#    82.345: every: 10s
#    92.626: every: 10s
#    95.059: cron: '*/10 * * * * *'
#   102.645: every: 10s
#   112.931: every: 10s
#   123.230: every: 10s
#   133.246: every: 10s
#   143.534: every: 10s
#   153.821: every: 10s
#   155.028: cron: '*/10 * * * * *'
#   164.107: every: 10s
#   ^C
#
# Note that the cronline gave the expected behavior at first,
# triggering every 10s or so.  However after a few iterations, it
# slows to every 60s.
#
# author: jhw@prosperworks.com
# incept: 2015-08-26
#

require 'rufus-scheduler'

START_TIME ||= Time.now.to_f

def log(last_time, msg)

  f = Time.now.to_f
  delta_t = f - START_TIME
  delta_l = f - last_time
  printf("%7.3f: +%06.3f %s\n", delta_t, delta_l, msg)
  $stdout.flush

  f
end

puts "#{$0}: using rufus-scheduler #{Rufus::Scheduler::VERSION}"

scheduler = Rufus::Scheduler.new

elt = START_TIME
clt = START_TIME

scheduler.every '10s' do
  elt = log(elt, "every: 10s")
end
scheduler.cron '*/10 * * * * *' do
  clt = log(clt, "cron: '*/10 * * * * *'")
end

scheduler.join

