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
        ) if es && es.find { |e| ! e.is_a?(Integer) }
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
        # little adjustment before starting

      loop do

        unless date_match?(time)
          time += (24 - time.hour) * 3600 - time.min * 60 - time.sec
          next
        end
        unless sub_match?(time, :hour, @hours)
          time += (60 - time.min) * 60 - time.sec
          next
        end
        unless sub_match?(time, :min, @minutes)
          time += 60 - time.sec
          next
        end
        unless sub_match?(time, :sec, @seconds)
          time += 1
          next
        end

        break
      end

      if @timezone
        time = @timezone.local_to_utc(time)
        time = time.getlocal unless now.utc?
      end

      time
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

        if it.match(/#[12345]$/)

          raise ArgumentError.new(
            "ranges are not supported for monthdays (#{it})"
          ) if it.index('-')

          (monthdays ||= []) << it

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
      return [ 'L' ] if item == 'L'
      return parse_list(item, min, max) if item.index(',')
      return parse_range(item, min, max) if item.match(/[*-\/]/)

      i = item.to_i

      i = min if i < min
      i = max if i > max

      [ i ]
    end

    def parse_list(item, min, max)

      l = item.split(',').collect { |i| parse_range(i, min, max) }.flatten

      raise ArgumentError.new(
        "found duplicates in #{item.inspect}"
      ) if l.uniq.size < l.size

      l
    end

    def parse_range(item, min, max)

      dash = item.index('-')
      slash = item.index('/')

      return parse_item(item, min, max) if (not slash) and (not dash)

      raise ArgumentError.new(
        "'L' (end of month) is not accepted in ranges, " +
        "#{item.inspect} is not valid"
      ) if item.index('L')

      inc = slash ? item[slash + 1..-1].to_i : 1

      istart = -1
      iend = -1

      if dash

        istart = item[0..dash - 1].to_i
        iend = (slash ? item[dash + 1..slash - 1] : item[dash + 1..-1]).to_i

      else # case */x

        istart = min
        iend = max
      end

      istart = min if istart < min
      iend = max if iend > max

      result = []

      value = istart
      loop do
        result << value
        value = value + inc
        break if value > iend
      end

      result
    end

    def sub_match?(time, accessor, values=:none)

      value, values =
        if values == :none
          [ time, accessor ]
        else
          [ time.send(accessor), values ]
        end

      return true if values.nil?
      return true if values.include?('L') && (time + 24 * 3600).day == 1

      values.include?(value)
    end

    def date_match?(date)

      return false unless sub_match?(date, :day, @days)
      return false unless sub_match?(date, :month, @months)
      return false unless sub_match?(date, :wday, @weekdays)
      return false unless sub_match?(CronLine.monthday(date), @monthdays)
      true
    end

    DAY_IN_SECONDS = 7 * 24 * 3600

    def self.monthday(date)

      count = 1
      date2 = date.dup

      loop do
        date2 = date2 - DAY_IN_SECONDS
        break if date2.month != date.month
        count = count + 1
      end

      "#{WEEKDAYS[date.wday]}##{count}"
    end
  end
end

