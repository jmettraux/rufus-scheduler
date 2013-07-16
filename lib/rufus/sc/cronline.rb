#--
# Copyright (c) 2006-2013, John Mettraux, jmettraux@gmail.com
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


module Rufus

  #
  # A 'cron line' is a line in the sense of a crontab
  # (man 5 crontab) file line.
  #
  class CronLine

    DAY_S = 24 * 3600
    WEEK_S = 7 * DAY_S

    # The string used for creating this cronline instance.
    #
    attr_reader :original

    attr_reader :seconds
    attr_reader :minutes
    attr_reader :hours
    attr_reader :days
    attr_reader :months
    attr_reader :weekdays
    attr_reader :monthdays
    attr_reader :timezone

    def initialize(line)

      super()

      @original = line

      items = line.split

      @timezone = (TZInfo::Timezone.get(items.last) rescue nil)
      items.pop if @timezone

      raise ArgumentError.new(
        "not a valid cronline : '#{line}'"
      ) unless items.length == 5 or items.length == 6

      offset = items.length - 5

      @seconds = offset == 1 ? parse_item(items[0], 0, 59) : [ 0 ]
      @minutes = parse_item(items[0 + offset], 0, 59)
      @hours = parse_item(items[1 + offset], 0, 24)
      @days = parse_item(items[2 + offset], 1, 31)
      @months = parse_item(items[3 + offset], 1, 12)
      @weekdays, @monthdays = parse_weekdays(items[4 + offset])

      [ @seconds, @minutes, @hours, @months ].each do |es|

        raise ArgumentError.new(
          "invalid cronline: '#{line}'"
        ) if es && es.find { |e| ! e.is_a?(Fixnum) }
      end
    end

    # Returns true if the given time matches this cron line.
    #
    def matches?(time)

      time = Time.at(time) unless time.kind_of?(Time)

      time = @timezone.utc_to_local(time.getutc) if @timezone

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
    #   Rufus::CronLine.new('30 7 * * *').next_time(
    #     Time.mktime(2008, 10, 24, 7, 29))
    #   #=> Fri Oct 24 07:30:00 -0500 2008
    #
    #   Rufus::CronLine.new('30 7 * * *').next_time(
    #     Time.utc(2008, 10, 24, 7, 29))
    #   #=> Fri Oct 24 07:30:00 UTC 2008
    #
    #   Rufus::CronLine.new('30 7 * * *').next_time(
    #     Time.utc(2008, 10, 24, 7, 29)).localtime
    #   #=> Fri Oct 24 02:30:00 -0500 2008
    #
    # (Thanks to K Liu for the note and the examples)
    #
    def next_time(now=Time.now)

      time = @timezone ? @timezone.utc_to_local(now.getutc) : now

      time = time - time.usec * 1e-6 + 1
        # small adjustment before starting

      loop do

        unless date_match?(time)
          time += (24 - time.hour) * 3600 - time.min * 60 - time.sec; next
        end
        unless sub_match?(time, :hour, @hours)
          time += (60 - time.min) * 60 - time.sec; next
        end
        unless sub_match?(time, :min, @minutes)
          time += 60 - time.sec; next
        end
        unless sub_match?(time, :sec, @seconds)
          time += 1; next
        end

        break
      end

      if @timezone
        time = @timezone.local_to_utc(time)
        time = time.getlocal unless now.utc?
      end

      time
    end

    # Returns the previous the cronline matched. It's like next_time, but
    # for the past.
    #
    def previous_time(now=Time.now)

      # looks back by slices of two hours,
      #
      # finds for '* * * * sun', '* * 13 * *' and '0 12 13 * *'
      # starting 1970, 1, 1 in 1.8 to 2 seconds (says Rspec)

      start = current = now - 2 * 3600
      result = nil

      loop do
        nex = next_time(current)
        return (result ? result : previous_time(start)) if nex > now
        result = current = nex
      end

      # never reached
    end

    # Returns an array of 6 arrays (seconds, minutes, hours, days,
    # months, weekdays).
    # This method is used by the cronline unit tests.
    #
    def to_array

      [
        @seconds,
        @minutes,
        @hours,
        @days,
        @months,
        @weekdays,
        @monthdays,
        @timezone ? @timezone.name : nil
      ]
    end

    private

    WEEKDAYS = %w[ sun mon tue wed thu fri sat ]

    def parse_weekdays(item)

      return nil if item == '*'

      items = item.downcase.split(',')

      weekdays = nil
      monthdays = nil

      items.each do |it|

        if m = it.match(/^(.+)#(l|-?[12345])$/)

          raise ArgumentError.new(
            "ranges are not supported for monthdays (#{it})"
          ) if m[1].index('-')

          expr = it.gsub(/#l/, '#-1')

          (monthdays ||= []) << expr

        else

          expr = it.dup
          WEEKDAYS.each_with_index { |a, i| expr.gsub!(/#{a}/, i.to_s) }

          raise ArgumentError.new(
            "invalid weekday expression (#{it})"
          ) if expr !~ /^0*[0-7](-0*[0-7])?$/

          its = expr.index('-') ? parse_range(expr, 0, 7) : [ Integer(expr) ]
          its = its.collect { |i| i == 7 ? 0 : i }

          (weekdays ||= []).concat(its)
        end
      end

      weekdays = weekdays.uniq if weekdays

      [ weekdays, monthdays ]
    end

    def parse_item(item, min, max)

      return nil if item == '*'

      r = item.split(',').map { |i| parse_range(i.strip, min, max) }.flatten

      raise ArgumentError.new(
        "found duplicates in #{item.inspect}"
      ) if r.uniq.size < r.size

      r
    end

    RANGE_REGEX = /^(\*|\d{1,2})(?:-(\d{1,2}))?(?:\/(\d{1,2}))?$/

    def parse_range(item, min, max)

      return %w[ L ] if item == 'L'

      item = '*' + item if item.match(/^\//)

      m = item.match(RANGE_REGEX)

      raise ArgumentError.new(
        "cannot parse #{item.inspect}"
      ) unless m

      sta = m[1]
      sta = sta == '*' ? min : sta.to_i

      edn = m[2]
      edn = edn ? edn.to_i : sta
      edn = max if m[1] == '*'

      inc = m[3]
      inc = inc ? inc.to_i : 1

      raise ArgumentError.new(
        "#{item.inspect} is not in range #{min}..#{max}"
      ) if sta < min or edn > max

      r = []
      val = sta

      loop do
        v = val
        v = 0 if max == 24 && v == 24
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
      return true if values.include?('L') && (time + DAY_S).day == 1

      return true if value == 0 && accessor == :hour && values.include?(24)

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

      [ "#{WEEKDAYS[date.wday]}##{pos}", "#{WEEKDAYS[date.wday]}##{neg}" ]
    end
  end
end

