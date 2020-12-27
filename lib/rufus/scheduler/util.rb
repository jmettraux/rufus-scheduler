
class Rufus::Scheduler

  class << self

    #--
    # time and string methods
    #++

    def parse(o, opts={})

      opts[:no_error] = true

      parse_cron(o, opts) ||
      parse_in(o, opts) || # covers 'every' schedule strings
      parse_at(o, opts) ||
      fail(ArgumentError.new("couldn't parse #{o.inspect} (#{o.class})"))
    end

    def parse_cron(o, opts={})

      opts[:no_error] ?
        Fugit.parse_cron(o) :
        Fugit.do_parse_cron(o)
    end

    def parse_in(o, opts={})

      #o.is_a?(String) ? parse_duration(o, opts) : o

      return parse_duration(o, opts) if o.is_a?(String)
      return o if o.is_a?(Numeric)

      fail ArgumentError.new("couldn't parse time point in #{o.inspect}")

    rescue ArgumentError => ae

      return nil if opts[:no_error]
      fail ae
    end

    def parse_at(o, opts={})

      return o if o.is_a?(EoTime)
      return EoTime.make(o) if o.is_a?(Time)
      EoTime.parse(o, opts)

    rescue StandardError => se

      return nil if opts[:no_error]
      fail se
    end

    # Turns a string like '1m10s' into a float like '70.0', more formally,
    # turns a time duration expressed as a string into a Float instance
    # (millisecond count).
    #
    # w -> week
    # d -> day
    # h -> hour
    # m -> minute
    # s -> second
    # M -> month
    # y -> year
    # 'nada' -> millisecond
    #
    # Some examples:
    #
    #   Rufus::Scheduler.parse_duration "0.5"    # => 0.5
    #   Rufus::Scheduler.parse_duration "500"    # => 0.5
    #   Rufus::Scheduler.parse_duration "1000"   # => 1.0
    #   Rufus::Scheduler.parse_duration "1h"     # => 3600.0
    #   Rufus::Scheduler.parse_duration "1h10s"  # => 3610.0
    #   Rufus::Scheduler.parse_duration "1w2d"   # => 777600.0
    #
    # Negative time strings are OK (Thanks Danny Fullerton):
    #
    #   Rufus::Scheduler.parse_duration "-0.5"   # => -0.5
    #   Rufus::Scheduler.parse_duration "-1h"    # => -3600.0
    #
    def parse_duration(str, opts={})

      d =
        opts[:no_error] ?
        Fugit::Duration.parse(str, opts) :
        Fugit::Duration.do_parse(str, opts)
      d ?
        d.to_sec :
        nil
    end

    # Turns a number of seconds into a a time string
    #
    #   Rufus.to_duration 0                    # => '0s'
    #   Rufus.to_duration 60                   # => '1m'
    #   Rufus.to_duration 3661                 # => '1h1m1s'
    #   Rufus.to_duration 7 * 24 * 3600        # => '1w'
    #   Rufus.to_duration 30 * 24 * 3600 + 1   # => "4w2d1s"
    #
    # It goes from seconds to the year. Months are not counted (as they
    # are of variable length). Weeks are counted.
    #
    # For 30 days months to be counted, the second parameter of this
    # method can be set to true.
    #
    #   Rufus.to_duration 30 * 24 * 3600 + 1, true   # => "1M1s"
    #
    # If a Float value is passed, milliseconds will be displayed without
    # 'marker'
    #
    #   Rufus.to_duration 0.051                       # => "51"
    #   Rufus.to_duration 7.051                       # => "7s51"
    #   Rufus.to_duration 0.120 + 30 * 24 * 3600 + 1  # => "4w2d1s120"
    #
    # (this behaviour mirrors the one found for parse_time_string()).
    #
    # Options are :
    #
    # * :months, if set to true, months (M) of 30 days will be taken into
    #   account when building up the result
    # * :drop_seconds, if set to true, seconds and milliseconds will be
    #   trimmed from the result
    #
    def to_duration(seconds, options={})

      #d = Fugit::Duration.parse(seconds, options).deflate
      #d = d.drop_seconds if options[:drop_seconds]
      #d = d.deflate(:month => options[:months]) if options[:months]
      #d.to_rufus_s

      to_fugit_duration(seconds, options).to_rufus_s
    end

    # Turns a number of seconds (integer or Float) into a hash like in :
    #
    #   Rufus.to_duration_hash 0.051
    #     # => { :s => 0.051 }
    #   Rufus.to_duration_hash 7.051
    #     # => { :s => 7.051 }
    #   Rufus.to_duration_hash 0.120 + 30 * 24 * 3600 + 1
    #     # => { :w => 4, :d => 2, :s => 1.120 }
    #
    # This method is used by to_duration behind the scenes.
    #
    # Options are :
    #
    # * :months, if set to true, months (M) of 30 days will be taken into
    #   account when building up the result
    # * :drop_seconds, if set to true, seconds and milliseconds will be
    #   trimmed from the result
    #
    def to_duration_hash(seconds, options={})

      to_fugit_duration(seconds, options).to_rufus_h
    end

    # Used by both .to_duration and .to_duration_hash
    #
    def to_fugit_duration(seconds, options={})

      d = Fugit::Duration
        .parse(seconds, options)
        .deflate

      d = d.drop_seconds if options[:drop_seconds]
      d = d.deflate(:month => options[:months]) if options[:months]

      d
    end

    #--
    # misc
    #++

    if RUBY_VERSION > '1.9.9'

      # Produces the UTC string representation of a Time instance
      #
      # like "2009/11/23 11:11:50.947109 UTC"
      #
      def utc_to_s(t=Time.now)
        "#{t.dup.utc.strftime('%F %T.%6N')} UTC"
      end

      # Produces a hour/min/sec/milli string representation of Time instance
      #
      def h_to_s(t=Time.now)
        t.strftime('%T.%6N')
      end
    else

      def utc_to_s(t=Time.now)
        "#{t.utc.strftime('%Y-%m-%d %H:%M:%S')}.#{sprintf('%06d', t.usec)} UTC"
      end
      def h_to_s(t=Time.now)
        "#{t.strftime('%H:%M:%S')}.#{sprintf('%06d', t.usec)}"
      end
    end

    if defined?(Process::CLOCK_MONOTONIC)
      def monow; Process.clock_gettime(Process::CLOCK_MONOTONIC); end
    else
      def monow; Time.now.to_f; end
    end

    def ltstamp; Time.now.strftime('%FT%T.%3N'); end
  end

  # Debugging tools...
  #
  class D

    def self.h_to_s(t=Time.now); Rufus::Scheduler.h_to_s(t); end
  end
end

