#--
# Copyright (c) 2006-2016, John Mettraux, jmettraux@gmail.com
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
# Made in Japan.
#++

require 'tzinfo'


class Rufus::Scheduler

  #
  # Zon{ing|ed}Time, whatever.
  #
  class ZoTime

    attr_accessor :seconds
    attr_accessor :zone

    def initialize(s, zone)

      @seconds = s.to_f
      @zone = self.class.get_tzone(zone || :current)

      fail ArgumentError.new(
        "cannot determine timezone from #{zone.inspect}"
      ) unless @zone
    end

    def utc

      Time.utc(1970, 1, 1) + @seconds
    end

    # Returns a Ruby Time instance. Warning: the timezone will be UTC.
    #
    def to_time

      u = utc; @zone.period_for_utc(u).to_local(u)
    end

    extend Forwardable
    delegate [
      :wday, :hour, :min, :>, :<
    ] => :to_time

    alias getutc utc
    alias getgm utc

    def to_i

      @seconds.to_i
    end

    def to_f

      @seconds
    end

    def is_dst?

      @zone.period_for_utc(utc).std_offset != 0
    end
    alias isdst is_dst?

    def strftime(format)

      format = format.gsub(/%(\/?Z|:{0,2}z)/) { |f| strfz(f) }

      to_time.strftime(format)
    end

    def add(t); @seconds += t.to_f; end
    def substract(t); @seconds -= t.to_f; end

    def -(t)

      if t.is_a?(Numeric)
        nt = self.dup
        nt.seconds -= t.to_f
        nt
      elsif t.respond_to?(:to_f)
        @seconds - t.to_f
      else
        fail ArgumentError.new(
          "cannot call ZoTime#- with arg of class #{t.class}")
      end
    end

    def self.parse(str, opts={})

      if defined?(::Chronic) && t = ::Chronic.parse(str, opts)
        return ZoTime.new(t, nil)
      end

      #begin
      #  DateTime.parse(str)
      #rescue
      #  fail ArgumentError, "no time information in #{o.inspect}"
      #end if RUBY_VERSION < '1.9.0'
        # disable that for now

      zone = nil

      s =
        str.gsub(/\S+/) do |w|
          if z = get_tzone(w)
            zone ||= z
            ''
          else
            w
          end
        end

      zone ||= get_tzone(:current)

      local = Time.parse(s) # disregard Ruby tz
      period = zone.period_for_local(local)
      secs = period.to_utc(local).to_f # UTC seconds

      ZoTime.new(secs, zone)
    end

    def self.get_tzone(str)

      str = Time.now.zone if str == :current

      return str if str.is_a?(::TZInfo::Timezone)

      # discard quickly when it's certainly not a timezone

      return nil if str == nil
      return nil if str == '*'

      return nil if str.index('#')
        # counters "sun#2", etc... On OSX would go all the way to true

      # vanilla time zones

      z = (::TZInfo::Timezone.get(str) rescue nil)
      return z if z

      # time zone abbreviations

      if str.match(/\A[A-Z0-9-]{3,6}\z/)

        twin = Time.utc(Time.now.year, 1, 1)
        tsum = Time.utc(Time.now.year, 7, 1)

        z =
          ::TZInfo::Timezone.all.find do |tz|
            tz.period_for_utc(twin).abbreviation.to_s == str ||
            tz.period_for_utc(tsum).abbreviation.to_s == str
          end
        return z if z
      end

      # some time zone aliases

      return ::TZInfo::Timezone.get('Zulu') if %w[ Z ].include?(str)

      # custom timezones, no DST, just an offset, like "+08:00" or "-01:30"

      tz = (@custom_tz_cache ||= {})[str]
      return tz if tz

      if m = str.match(/\A([+-][0-1][0-9]):?([0-5][0-9])\z/)

        hr = m[1].to_i
        mn = m[2].to_i

        hr = nil if hr.abs > 11
        hr = nil if mn > 59
        mn = -mn if hr && hr < 0

        return (
          @custom_tz_cache[str] =
            begin
              tzi = TZInfo::TransitionDataTimezoneInfo.new(str)
              tzi.offset(str, hr * 3600 + mn * 60, 0, str)
              tzi.create_timezone
            end
        ) if hr
      end

      # so it's not a timezone.

      nil
    end

#    def in_zone(&block)
#
#      current_timezone = ENV['TZ']
#      ENV['TZ'] = @zone
#
#      block.call
#
#    ensure
#
#      ENV['TZ'] = current_timezone
#    end

    protected

    def strfz(code)

      return @zone.name if code == '%/Z'

      per = @zone.period_for_utc(utc)

      return per.abbreviation.to_s if code == '%Z'

      off = per.utc_total_offset
        #
      sn = off < 0 ? '-' : '+'; off = off.abs
      hr = off / 3600
      mn = (off % 3600) / 60
      sc = 0

      fmt =
        if code == '%z'
          "%s%02d%02d"
        elsif code == '%:z'
          "%s%02d:%02d"
        else
          "%s%02d:%02d:%02d"
        end

      fmt % [ sn, hr, mn, sc ]
    end
  end
end

