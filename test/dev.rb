
require File.dirname(__FILE__) + '/test_base'

s = Rufus::Scheduler.new
s.precision = 1.250
#s.precision = 0.250
#s.precision = 30
s.start

def compute_dev (s, t0, t1)

  return 0.0 unless t0
  s.precision - (t1 - t0)
end

tprev = nil
tcurr = nil

#s.schedule "* * * * * *" do
s.schedule "* * * * *" do
  tprev = tcurr
  tcurr = Time.new
  puts "#{tcurr.to_s} #{tcurr.to_f}  (#{compute_dev(s, tprev, tcurr)})"
end

s.join

