#--
# Copyright (c) 2006-2009, John Mettraux, jmettraux@gmail.com
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


module Rufus

  #
  # A 'cron line' is a line in the sense of a crontab
  # (man 5 crontab) file line.
  #
  class CronLine

    #
    # The string used for creating this cronline instance.
    #
    attr_reader :original

    attr_reader \
      :seconds,
      :minutes,
      :hours,
      :days,
      :months,
      :weekdays

    def initialize (line)

      super()

      @original = line

      items = line.split

      unless items.length == 5 or items.length == 6
        raise(
          "cron '#{line}' string should hold 5 or 6 items, not #{items.length}")
      end

      offset = items.length - 5

      @seconds = offset == 1 ? parse_item(items[0], 0, 59) : [ 0 ]
      @minutes = parse_item(items[0 + offset], 0, 59)
      @hours = parse_item(items[1 + offset], 0, 24)
      @days = parse_item(items[2 + offset], 1, 31)
      @months = parse_item(items[3 + offset], 1, 12)
      @weekdays = parse_weekdays(items[4 + offset])
    end

    #
    # Returns true if the given time matches this cron line.
    #
    def matches? (time)

      time = Time.at(time) unless time.kind_of?(Time)

      return false unless sub_match?(time.sec, @seconds)
      return false unless sub_match?(time.min, @minutes)
      return false unless sub_match?(time.hour, @hours)
      return false unless sub_match?(time.day, @days)
      return false unless sub_match?(time.month, @months)
      return false unless sub_match?(time.wday, @weekdays)
      true
    end

    #
    # Returns an array of 6 arrays (seconds, minutes, hours, days,
    # months, weekdays).
    # This method is used by the cronline unit tests.
    #
    def to_array

      [ @seconds, @minutes, @hours, @days, @months, @weekdays ]
    end

    #
    # Returns the next time that this cron line is supposed to 'fire'
    #
    # This is raw, 3 secs to iterate over 1 year on my macbook :( brutal.
    #
    # This method accepts an optional Time parameter. It's the starting point
    # for the 'search'. By default, it's Time.now
    #
    # Note that the time instance returned will be in the same time zone that
    # the given start point Time (thus a result in the local time zone will
    # be passed if no start time is specified (search start time set to
    # Time.now))
    #
    #   >> Rufus::CronLine.new('30 7 * * *').next_time( Time.mktime(2008,10,24,7,29) )
    #   => Fri Oct 24 07:30:00 -0500 2008
    #
    #   >> Rufus::CronLine.new('30 7 * * *').next_time( Time.utc(2008,10,24,7,29) )
    #   => Fri Oct 24 07:30:00 UTC 2008
    #
    #   >> Rufus::CronLine.new('30 7 * * *').next_time( Time.utc(2008,10,24,7,29)  ).localtime
    #   => Fri Oct 24 02:30:00 -0500 2008
    #
    # (Thanks to K Liu for the note and the examples)
    #
    def next_time (time=Time.now)

      time -= time.usec * 1e-6
      time += 1

      loop do

        unless date_match?(time)
          time += (24 - time.hour) * 3600 - time.min * 60 - time.sec
          next
        end

        unless sub_match?(time.hour, @hours)
          time += (60 - time.min) * 60 - time.sec
          next
        end

        unless sub_match?(time.min, @minutes)
          time += 60 - time.sec
          next
        end

        unless sub_match?(time.sec, @seconds)
          time += 1
          next
        end

        break
      end

      time
    end

    private

    WDS = %w[ sun mon tue wed thu fri sat ]
      #
      # used by parse_weekday()

    def parse_weekdays (item)

      item = item.downcase

      WDS.each_with_index { |day, index| item = item.gsub(day, index.to_s) }

      r = parse_item(item, 0, 7)

      r.is_a?(Array) ?
        r.collect { |e| e == 7 ? 0 : e }.uniq :
        r
    end

    def parse_item (item, min, max)

      return nil if item == '*'
      return parse_list(item, min, max) if item.index(',')
      return parse_range(item, min, max) if item.index('*') or item.index('-')

      i = Integer(item)

      i = min if i < min
      i = max if i > max

      [ i ]
    end

    def parse_list (item, min, max)

      item.split(',').inject([]) { |r, i|
        r.push(parse_range(i, min, max))
      }.flatten
    end

    def parse_range (item, min, max)

      i = item.index('-')
      j = item.index('/')

      return item.to_i if (not i and not j)

      inc = j ? Integer(item[j+1..-1]) : 1

      istart = -1
      iend = -1

      if i

        istart = Integer(item[0..i - 1])

        if j
          iend = Integer(item[i + 1..j])
        else
          iend = Integer(item[i + 1..-1])
        end

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

    def sub_match?(value, values)
      values.nil? || values.include?(value)
    end

    def date_match?(date)
      return false unless sub_match?(date.day, @days)
      return false unless sub_match?(date.month, @months)
      return false unless sub_match?(date.wday, @weekdays)
      true
    end
  end

end

