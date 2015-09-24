#--
# Copyright (c) 2006-2015, John Mettraux, jmettraux@gmail.com
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

require 'rufus/scheduler/zones'


class Rufus::Scheduler

  #
  # Zon{ing|ed}Time, whatever.
  #
  class ZoTime

    attr_accessor :seconds
    attr_accessor :zone

    def initialize(s, zone)

      @seconds = s.to_f
      @zone = zone
    end

    def time

      in_zone do

        t = Time.at(@seconds)

        if t.isdst
          t1 = Time.at(@seconds + 3600)
          t = t1 if t.zone != t1.zone && t.hour == t1.hour && t.min == t1.min
            # ambiguous TZ (getting out of DST)
        else
          t.hour # force t to compute itself
        end

        t
      end
    end

    def utc

      time.utc
    end

    def add(s)

      @seconds += s.to_f
    end

    def substract(s)

      @seconds -= s.to_f
    end

    def to_f

      @seconds
    end

    #DELTA_TZ_REX = /^[+-][0-1][0-9]:?[0-5][0-9]$/

    def self.envtzable?(s)

      TIMEZONES.include?(s)
    end

    def self.parse(str, opts={})

      if defined?(::Chronic) && t = ::Chronic.parse(str, opts)
        return ZoTime.new(t, ENV['TZ'])
      end

      begin
        DateTime.parse(str)
      rescue
        raise ArgumentError, "no time information in #{o.inspect}"
      end if RUBY_VERSION < '1.9.0'

      zone = nil

      s =
        str.gsub(/\S+/) { |m|
          if envtzable?(m)
            zone ||= m
            ''
          else
            m
          end
        }

      return nil unless zone.nil? || is_timezone?(zone)

      zt = ZoTime.new(0, zone || ENV['TZ'])
      zt.in_zone { zt.seconds = Time.parse(s).to_f }

      zt.seconds == nil ? nil : zt
    end

    def self.is_timezone?(str)

      return false if str == nil
      return false if str == '*'

      return false if str.index('#')
        # "sun#2", etc... On OSX would go all the way to true

      return true if Time.zone_offset(str)

      return !! (::TZInfo::Timezone.get(str) rescue nil) if defined?(::TZInfo)

      return true if TIMEZONES.include?(str)
      return true if TIMEZONEs.include?(str)

      t = ZoTime.new(0, str).time

      return false if t.zone == ''
      return false if t.zone == 'UTC'
      return false if t.utc_offset == 0 && str.start_with?(t.zone)
        # 3 common fallbacks...

      return false if RUBY_PLATFORM.include?('java') && ! envtzable?(str)

      true
    end

    def in_zone(&block)

      current_timezone = ENV['TZ']
      ENV['TZ'] = @zone

      block.call

    ensure

      ENV['TZ'] = current_timezone
    end
  end
end

