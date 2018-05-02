
#
# Specifying rufus-scheduler
#
# Wed Apr 17 06:00:59 JST 2013
#

require 'pp'

Thread.abort_on_exception = true

require 'stringio'
require 'rufus-scheduler'


puts
puts __FILE__
puts
puts "RUBY_VERSION   => #{RUBY_VERSION.inspect}"
puts "RUBY_PLATFORM  => #{RUBY_PLATFORM.inspect}"
puts
puts "ENV['TZ']                          => #{ENV['TZ'].inspect}"
puts "Time.now.zone                      => #{Time.now.zone.inspect}"
puts "Time.now.strftime('%z')            => #{Time.now.strftime('%z').inspect}"
puts "EtOrbi::EoTime.now.zone            => #{EtOrbi::EoTime.now.zone.inspect}"
puts "EtOrbi::EoTime.now.strftime('%z')  => #{EtOrbi::EoTime.now.strftime('%z').inspect}"
puts


#
# misc helper methods

module Helpers

  def ruby18?

    !! RUBY_VERSION.match(/^1\.8\./)
  end

  def jruby?

    !! RUBY_PLATFORM.match(/java/)
  end

  def local(*args)

    Time.local(*args)
  end
  alias lo local

  def zlocal(*args)

    EtOrbi::EoTime.new(Time.local(*args).to_f, nil)
  end
  alias zlo zlocal

  def utc(*args)

    Time.utc(*args)
  end

  def zutc(*args)

    EtOrbi::EoTime.new(Time.utc(*args), 'Zulu')
  end

  def ltz(tz, *args)

    in_zone(tz) { Time.local(*args) }
  end

  def ltu(tz, *args)

    in_zone(tz) { Time.local(*args) }.getutc
  end

  def ztz(tz, *args)

    EtOrbi::EoTime.new(Time.local(*args), tz)
  end

  def ztu(tz, *args)

    EtOrbi::EoTime.new(Time.utc(*args), tz)
  end

  def sleep_until_next_minute

    min = Time.now.min
    while Time.now.min == min; sleep 2; end
  end

  def sleep_until_next_second

    sec = Time.now.sec
    while Time.now.sec == sec; sleep 0.2; end
  end

  def in_zone(zone_name, &block)

    prev_tz = ENV['TZ']
    ENV['TZ'] = zone_name

    block.call

  ensure

    ENV['TZ'] = prev_tz
  end

  def with_chronic(&block)

    require 'chronic'

    Object.const_set(:Khronic, Chronic) unless defined?(Khronic)
    Object.const_set(:Chronic, Khronic) unless defined?(Chronic)

    block.call

  ensure

    Object.send(:remove_const, :Chronic)
  end

  def without_chronic(&block) # for quick counter-tests ;-)

    block.call
  end

  def wait_until(timeout=14, frequency=0.1, &block)

    start = Time.now

    loop do

      sleep(frequency)

      #return if block.call == true
      r = block.call
      return r if r

      break if Time.now - start > timeout
    end

    fail "timeout after #{timeout}s"
  end
  alias :wait_for :wait_until
end
RSpec.configure { |c| c.include(Helpers) }


class Time

  def to_debug_s

    uo = self.utc_offset
    uos = uo < 0 ? '-' : '+'
    uo = uo.abs
    uoh, uom = [ uo / 3600, uo % 3600 ]

    [
      't',
      self.strftime('%Y-%m-%d %H:%M:%S'),
      "%s%02d:%02d" % [ uos, uoh, uom ],
      "dst:#{self.isdst}"
    ].join(' ')
  end
end

class TZInfo::Timezone

  def _name
    case name
    when /UTC\z/ then 'UTC'
    else name
    end
  end
end


#
# matchers

#require 'rspec/expectations'

RSpec::Matchers.define :be_within_1s_of do |expected, suffix|

  match do |actual|

    if actual.respond_to?(:asctime)
      (actual.to_f - expected.to_f).abs <= 1.0
    else
      false
    end
  end

  failure_message do |actual|

    if actual.respond_to?(:asctime)
      "expected #{actual.inspect} to be within 1 second of #{expected}" +
      (suffix ? ' ' + suffix : '')
    else
      "expected a EoTime instance, got a #{actual.inspect}"
    end
  end
end


#
# configure

#RSpec.configure do |config|
#end

