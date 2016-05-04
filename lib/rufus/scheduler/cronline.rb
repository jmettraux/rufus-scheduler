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

require 'set'


class Rufus::Scheduler

  #
  # A 'cron line' is a line in the sense of a crontab
  # (man 5 crontab) file line.
  #
  class CronLine

    # The string used for creating this cronline instance.
    #
    attr_reader :original

    attr_reader :seconds
    attr_reader :minutes
    attr_reader :hours
    attr_reader :days
    attr_reader :months
    #attr_reader :monthdays # reader defined below
    attr_reader :weekdays
    attr_reader :timezone

    def initialize(line)

      fail ArgumentError.new(
        "not a string: #{line.inspect}"
      ) unless line.is_a?(String)

      @original = line

      items = line.split

      @timezone = items.pop if ZoTime.is_timezone?(items.last)

      fail ArgumentError.new(
        "not a valid cronline : '#{line}'"
      ) unless items.length == 5 or items.length == 6

      offset = items.length - 5

      @seconds = offset == 1 ? parse_item(items[0], 0, 59) : [ 0 ]
      @minutes = parse_item(items[0 + offset], 0, 59)
      @hours = parse_item(items[1 + offset], 0, 24)
      @days = parse_item(items[2 + offset], -30, 31)
      @months = parse_item(items[3 + offset], 1, 12)
      @weekdays, @monthdays = parse_weekdays(items[4 + offset])

      [ @seconds, @minutes, @hours, @months ].each do |es|

        fail ArgumentError.new(
          "invalid cronline: '#{line}'"
        ) if es && es.find { |e| ! e.is_a?(Fixnum) }
      end
    end

    # Returns true if the given time matches this cron line.
    #
    def matches?(time)

      time = ZoTime.new(time.to_f, @timezone || ENV['TZ']).time

      return false unless sub_match?(time, :sec, @seconds)
      return false unless sub_match?(time, :min, @minutes)
      return false unless sub_match?(time, :hour, @hours)
      return false unless date_match?(time)
      true
    end

    # Returns the next time that this cron line is supposed to 'fire'
    #
    # This is raw, 3 secs to iterate over 1 year on my macbook :( brutal.
    # (Well, I was wrong, takes 0.001 sec on 1.8.7 and 1.9.1)
    #
    # This method accepts an optional Time parameter. It's the starting point
    # for the 'search'. By default, it's Time.now
    #
    # Note that the time instance returned will be in the same time zone that
    # the given start point Time (thus a result in the local time zone will
    # be passed if no start time is specified (search start time set to
    # Time.now))
    #
    #   Rufus::Scheduler::CronLine.new('30 7 * * *').next_time(
    #     Time.mktime(2008, 10, 24, 7, 29))
    #   #=> Fri Oct 24 07:30:00 -0500 2008
    #
    #   Rufus::Scheduler::CronLine.new('30 7 * * *').next_time(
    #     Time.utc(2008, 10, 24, 7, 29))
    #   #=> Fri Oct 24 07:30:00 UTC 2008
    #
    #   Rufus::Scheduler::CronLine.new('30 7 * * *').next_time(
    #     Time.utc(2008, 10, 24, 7, 29)).localtime
    #   #=> Fri Oct 24 02:30:00 -0500 2008
    #
    # (Thanks to K Liu for the note and the examples)
    #
    def next_time(from=Time.now)

      time = nil
      zotime = ZoTime.new(from.to_i + 1, @timezone || ENV['TZ'])

      loop do

        time = zotime.time

        unless date_match?(time)
          zotime.add((24 - time.hour) * 3600 - time.min * 60 - time.sec)
          next
        end
        unless sub_match?(time, :hour, @hours)
          zotime.add((60 - time.min) * 60 - time.sec)
          next
        end
        unless sub_match?(time, :min, @minutes)
          zotime.add(60 - time.sec)
          next
        end
        unless sub_match?(time, :sec, @seconds)
          zotime.add(next_second(time))
          next
        end

        break
      end

      time
    end

    # Returns the previous time the cronline matched. It's like next_time, but
    # for the past.
    #
    def previous_time(from=Time.now)

      time = nil
      zotime = ZoTime.new(from.to_i - 1, @timezone || ENV['TZ'])

      loop do

        time = zotime.time

        unless date_match?(time)
          zotime.substract(time.hour * 3600 + time.min * 60 + time.sec + 1)
          next
        end
        unless sub_match?(time, :hour, @hours)
          zotime.substract(time.min * 60 + time.sec + 1)
          next
        end
        unless sub_match?(time, :min, @minutes)
          zotime.substract(time.sec + 1)
          next
        end
        unless sub_match?(time, :sec, @seconds)
          zotime.substract(prev_second(time))
          next
        end

        break
      end

      time
    end

    # Returns an array of 6 arrays (seconds, minutes, hours, days,
    # months, weekdays).
    # This method is mostly used by the cronline specs.
    #
    def to_a

      [
        toa(@seconds),
        toa(@minutes),
        toa(@hours),
        toa(@days),
        toa(@months),
        toa(@weekdays),
        toa(@monthdays),
        @timezone
      ]
    end
    alias to_array to_a

    # Returns a quickly computed approximation of the frequency for this
    # cron line.
    #
    # #brute_frequency, on the other hand, will compute the frequency by
    # examining a whole year, that can take more than seconds for a seconds
    # level cron...
    #
    def frequency

      return brute_frequency unless @seconds && @seconds.length > 1

      secs = toa(@seconds)

      secs[1..-1].inject([ secs[0], 60 ]) { |(prev, delta), sec|
        d = sec - prev
        [ sec, d < delta ? d : delta ]
      }[1]
    end

    # Caching facility. Currently only used for brute frequencies.
    #
    @cache = {}; class << self; attr_reader :cache; end

    # Returns the shortest delta between two potential occurences of the
    # schedule described by this cronline.
    #
    # .
    #
    # For a simple cronline like "*/5 * * * *", obviously the frequency is
    # five minutes. Why does this method look at a whole year of #next_time ?
    #
    # Consider "* * * * sun#2,sun#3", the computed frequency is 1 week
    # (the shortest delta is the one between the second sunday and the third
    # sunday). This method takes no chance and runs next_time for the span
    # of a whole year and keeps the shortest.
    #
    # Of course, this method can get VERY slow if you call on it a second-
    # based cronline...
    #
    def brute_frequency

      key = "brute_frequency:#{@original}"

      delta = self.class.cache[key]
      return delta if delta

      delta = 366 * DAY_S

      t0 = previous_time(Time.local(2000, 1, 1))

      loop do

        break if delta <= 1
        break if delta <= 60 && @seconds && @seconds.size == 1

        t1 = next_time(t0)
        d = t1 - t0
        delta = d if d < delta

        break if @months == nil && t1.month == 2
        break if t1.year >= 2001

        t0 = t1
      end

      self.class.cache[key] = delta
    end

    def next_second(time)

      secs = toa(@seconds)

      return secs.first + 60 - time.sec if time.sec > secs.last

      secs.shift while secs.first < time.sec

      secs.first - time.sec
    end

    def prev_second(time)

      secs = toa(@seconds)

      return time.sec + 60 - secs.last if time.sec < secs.first

      secs.pop while time.sec < secs.last

      time.sec - secs.last
    end

    protected

    def sc_sort(a)

      a.sort_by { |e| e.is_a?(String) ? 61 : e.to_i }
    end

    if RUBY_VERSION >= '1.9'
      def toa(item)
        item == nil ? nil : item.to_a
      end
    else
      def toa(item)
        item.is_a?(Set) ? sc_sort(item.to_a) : item
      end
    end

    WEEKDAYS = %w[ sun mon tue wed thu fri sat ]
    DAY_S = 24 * 3600
    WEEK_S = 7 * DAY_S

    def parse_weekdays(item)

      return nil if item == '*'

      weekdays = nil
      monthdays = nil

      item.downcase.split(',').each do |it|

        WEEKDAYS.each_with_index { |a, i| it.gsub!(/#{a}/, i.to_s) }

        it = it.gsub(/([^#])l/, '\1#-1')
          # "5L" == "5#-1" == the last Friday

        if m = it.match(/\A(.+)#(l|-?[12345])\z/)

          fail ArgumentError.new(
            "ranges are not supported for monthdays (#{it})"
          ) if m[1].index('-')

          it = it.gsub(/#l/, '#-1')

          (monthdays ||= []) << it

        else

          fail ArgumentError.new(
            "invalid weekday expression (#{item})"
          ) if it !~ /\A0*[0-7](-0*[0-7])?\z/

          its = it.index('-') ? parse_range(it, 0, 7) : [ Integer(it) ]
          its = its.collect { |i| i == 7 ? 0 : i }

          (weekdays ||= []).concat(its)
        end
      end

      weekdays = weekdays.uniq.sort if weekdays

      [ weekdays, monthdays ]
    end

    def parse_item(item, min, max)

      return nil if item == '*'

      r = item.split(',').map { |i| parse_range(i.strip, min, max) }.flatten

      fail ArgumentError.new(
        "found duplicates in #{item.inspect}"
      ) if r.uniq.size < r.size

      r = sc_sort(r)

      Set.new(r)
    end

    RANGE_REGEX = /\A(\*|-?\d{1,2})(?:-(-?\d{1,2}))?(?:\/(\d{1,2}))?\z/

    def parse_range(item, min, max)

      return %w[ L ] if item == 'L'

      item = '*' + item if item[0, 1] == '/'

      m = item.match(RANGE_REGEX)

      fail ArgumentError.new(
        "cannot parse #{item.inspect}"
      ) unless m

      mmin = min == -30 ? 1 : min # days

      sta = m[1]
      sta = sta == '*' ? mmin : sta.to_i

      edn = m[2]
      edn = edn ? edn.to_i : sta
      edn = max if m[1] == '*'

      inc = m[3]
      inc = inc ? inc.to_i : 1

      fail ArgumentError.new(
        "#{item.inspect} positive/negative ranges not allowed"
      ) if (sta < 0 && edn > 0) || (sta > 0 && edn < 0)

      fail ArgumentError.new(
        "#{item.inspect} descending day ranges not allowed"
      ) if min == -30 && sta > edn

      fail ArgumentError.new(
        "#{item.inspect} is not in range #{min}..#{max}"
      ) if sta < min || edn > max

      fail ArgumentError.new(
        "#{item.inspect} increment must be greater than zero"
      ) if inc == 0

      r = []
      val = sta

      loop do
        v = val
        v = 0 if max == 24 && v == 24 # hours
        r << v
        break if inc == 1 && val == edn
        val += inc
        break if inc > 1 && val > edn
        val = min if val > max
      end

      r.uniq
    end

    def sub_match?(time, accessor, values)

      value = time.send(accessor)

      return true if values.nil?

      if accessor == :day

        values.each do |v|
          return true if v == 'L' && (time + DAY_S).day == 1
          return true if v.to_i < 0 && (time + (1 - v) * DAY_S).day == 1
        end
      end

      if accessor == :hour

        return true if value == 0 && values.include?(24)
      end

      values.include?(value)
    end

    def monthday_match?(date, values)

      return true if values.nil?

      today_values = monthdays(date)

      (today_values & values).any?
    end

    def date_match?(date)

      return false unless sub_match?(date, :day, @days)
      return false unless sub_match?(date, :month, @months)
      return false unless sub_match?(date, :wday, @weekdays)
      return false unless monthday_match?(date, @monthdays)
      true
    end

    def monthdays(date)

      pos = 1
      d = date.dup

      loop do
        d = d - WEEK_S
        break if d.month != date.month
        pos = pos + 1
      end

      neg = -1
      d = date.dup

      loop do
        d = d + WEEK_S
        break if d.month != date.month
        neg = neg - 1
      end

      [ "#{date.wday}##{pos}", "#{date.wday}##{neg}" ]
    end
  end
end

