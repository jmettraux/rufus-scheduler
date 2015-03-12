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
        t.sec # force Time instance to "compute" itself...

        t
      end
    end

    def utc

      time.utc
    end

    def add(s)

      @seconds += s.to_f
    end

    def to_f

      @seconds
    end

    def self.parse(str)

      begin
        DateTime.parse(str)
      rescue
        raise ArgumentError, "no time information in #{o.inspect}"
      end if RUBY_VERSION < '1.9.0'

      zone = nil

      s =
        str.gsub(/\S+/) { |m|
          if is_timezone?(m)
            zone ||= m
            ''
          else
            m
          end
        }

      zt = ZoTime.new(0, zone || ENV['TZ'])
      zt.in_zone { zt.seconds = Time.parse(s).to_f }

      zt.seconds == nil ? nil : zt
    end

    def self.is_timezone?(str)

      return false if str == nil

      return true if Time.zone_offset(str)

      zt = ZoTime.new(0, str)
      t = zt.time

      return !! (TZInfo::Timezone.get(str) rescue nil) if defined?(::TZInfo)

      return false if t.zone == ''
      return false if t.zone == 'UTC' && str != 'UTC'
      return false if str.start_with?(t.zone)

      true
    end

    def in_zone(&block)

      ptz = ENV['TZ']
      ENV['TZ'] = @zone

      block.call

    ensure

      ENV['TZ'] = ptz
    end
  end
end

