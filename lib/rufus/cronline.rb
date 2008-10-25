#
#--
# Copyright (c) 2006-2008, John Mettraux, jmettraux@gmail.com
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
#++
#

#
# "made in Japan"
#
# John Mettraux at openwfe.org
#

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

      unless [ 5, 6 ].include?(items.length)
        raise \
          "cron '#{line}' string should hold 5 or 6 items, " +
          "not #{items.length}" \
      end

      offset = items.length - 5

      @seconds = if offset == 1
        parse_item(items[0], 0, 59)
      else
        [ 0 ]
      end
      @minutes = parse_item(items[0+offset], 0, 59)
      @hours = parse_item(items[1+offset], 0, 24)
      @days = parse_item(items[2+offset], 1, 31)
      @months = parse_item(items[3+offset], 1, 12)
      @weekdays = parse_weekdays(items[4+offset])

      #adjust_arrays()
    end

    #
    # Returns true if the given time matches this cron line.
    #
    # (the precision is passed as well to determine if it's
    # worth checking seconds and minutes)
    #
    def matches? (time)
    #def matches? (time, precision)

      time = Time.at(time) unless time.kind_of?(Time)

      return false \
        if no_match?(time.sec, @seconds)
        #if precision <= 1 and no_match?(time.sec, @seconds)
      return false \
        if no_match?(time.min, @minutes)
        #if precision <= 60 and no_match?(time.min, @minutes)
      return false \
        if no_match?(time.hour, @hours)
      return false \
        if no_match?(time.day, @days)
      return false \
        if no_match?(time.month, @months)
      return false \
        if no_match?(time.wday, @weekdays)

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
    def next_time (now = Time.now)

      #
      # position now to the next cron second

      if @seconds
        next_sec = @seconds.find { |s| s > now.sec } || 60 + @seconds.first
        now += next_sec - now.sec
      else
        now += 1
      end

      #
      # prepare sec jump array

      sjarray = nil

      if @seconds

        sjarray = []

        i = @seconds.index(now.sec)
        ii = i

        loop do
          cur = @seconds[ii]
          ii += 1
          ii = 0 if ii == @seconds.size
          nxt = @seconds[ii]
          nxt += 60 if ii == 0
          sjarray << (nxt - cur)
          break if ii == i
        end

      else

        sjarray = [ 1 ]
      end

      #
      # ok, seek...

      i = 0

      loop do
        return now if matches?(now)
        now += sjarray[i]
        i += 1
        i = 0 if i == sjarray.size
        # danger... potentially no exit...
      end

      nil
    end

    private

      #--
      # adjust values to Ruby
      #
      #def adjust_arrays()
      #  @hours = @hours.collect { |h|
      #    if h == 24
      #      0
      #    else
      #      h
      #    end
      #  } if @hours
      #  @weekdays = @weekdays.collect { |wd|
      #    wd - 1
      #  } if @weekdays
      #end
        #
        # dead code, keeping it as a reminder
      #++

      WDS = [ "sun", "mon", "tue", "wed", "thu", "fri", "sat" ]
        #
        # used by parse_weekday()

      def parse_weekdays (item)

        item = item.downcase

        WDS.each_with_index do |day, index|
          item = item.gsub day, "#{index}"
        end

        r = parse_item item, 0, 7

        return r unless r.is_a?(Array)

        r.collect { |e| e == 7 ? 0 : e }.uniq
      end

      def parse_item (item, min, max)

        return nil \
          if item == "*"
        return parse_list(item, min, max) \
          if item.index(",")
        return parse_range(item, min, max) \
          if item.index("*") or item.index("-")

        i = Integer(item)

        i = min if i < min
        i = max if i > max

        [ i ]
      end

      def parse_list (item, min, max)

        items = item.split(",")

        items.inject([]) { |r, i| r.push(parse_range(i, min, max)) }.flatten
      end

      def parse_range (item, min, max)

        i = item.index("-")
        j = item.index("/")

        return item.to_i if (not i and not j)

        inc = 1

        inc = Integer(item[j+1..-1]) if j

        istart = -1
        iend = -1

        if i

          istart = Integer(item[0..i-1])

          if j
            iend = Integer(item[i+1..j])
          else
            iend = Integer(item[i+1..-1])
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

      def no_match? (value, cron_values)

        return false if not cron_values

        cron_values.each do |v|
          return false if value == v # ok, it matches
        end

        true # no match found
      end
  end

end

