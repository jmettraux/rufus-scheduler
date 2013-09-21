
#
# Specifying rufus-scheduler
#
# Wed Apr 17 06:00:59 JST 2013
#

Thread.abort_on_exception = true


require 'stringio'
require 'rufus-scheduler'


def local(*args)

  Time.local(*args)
end
alias lo local

def utc(*args)

  Time.utc(*args)
end

def sleep_until_next_minute

  min = Time.now.min
  while Time.now.min == min; sleep 2; end
end

def sleep_until_next_second

  sec = Time.now.sec
  while Time.now.sec == sec; sleep 0.2; end
end


#require 'rspec/expectations'

RSpec::Matchers.define :be_within_1s_of do |expected|

  match do |actual|

    if actual.respond_to?(:asctime)
      (actual.to_f - expected.to_f).abs <= 1.0
    else
      false
    end
  end

  failure_message_for_should do |actual|

    if actual.respond_to?(:asctime)
      "expected #{actual.inspect} to be within 1 second of #{expected}"
    else
      "expected Time instance, got a #{actual.inspect}"
    end
  end
end


#RSpec.configure do |config|
#end

