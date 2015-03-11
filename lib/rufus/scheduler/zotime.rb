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

    TZ_REGEX = /\b((?:[a-zA-Z][a-zA-z0-9\-+]+)(?:\/[a-zA-Z0-9_\-+]+)?)\b/
      # yes, duplication, this one or this other must die

    def self.parse(str)

      zone = nil

      s =
        str.gsub(TZ_REGEX) { |m|
          zone ||= m
          is_timezone?(m) ? '' : m
        }

      begin
        DateTime.parse(o)
      rescue
        raise ArgumentError, "no time information in #{o.inspect}"
      end if RUBY_VERSION < '1.9.0'

      zt = ZoTime.new(0, zone)
      zt.in_zone { zt.seconds = Time.parse(s).to_f }

      zt
    end

    def self.is_timezone?(str)

      return false if str == nil

      zt = ZoTime.new(0, str)
      t = zt.time

      return false if t.zone == ''
      return true if t.zone != str
      return true if t.zone == 'UTC'

      false
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

