
class Rufus::Scheduler::RepeatJob < Rufus::Scheduler::Job

  attr_reader :paused_at

  attr_reader :first_at
  attr_reader :last_at
  attr_accessor :times

  def initialize(scheduler, duration, opts, block)

    super

    @paused_at = nil

    @times = opts[:times]

    @first_at_no_error = opts[:first_at_no_error] || false

    fail ArgumentError.new(
      "cannot accept :times => #{@times.inspect}, not nil or an int"
    ) unless @times == nil || @times.is_a?(Integer)

    self.first_at =
      opts[:first] || opts[:first_time] ||
      opts[:first_at] || opts[:first_in] ||
      nil
    self.last_at =
      opts[:last] || opts[:last_at] || opts[:last_in]

    @resume_discard_past = nil
  end

  FIRSTS = [ :now, :immediately, 0 ].freeze

  def first_at=(first)

    return (@first_at = nil) if first == nil

    n0 = EoTime.now
    n1 = n0 + 0.003

    first = n0 if FIRSTS.include?(first)
    fdur = Rufus::Scheduler.parse_duration(first, no_error: true)

    @first_at = (fdur && (EoTime.now + fdur)) || EoTime.make(first)
    @first_at = n1 if @first_at >= n0 && @first_at < n1
    @first_at = n0 if @first_at < n0 && @first_at_no_error

    fail ArgumentError.new(
      "cannot set first[_at|_in] in the past: " +
      "#{first.inspect} -> #{@first_at.inspect}"
    ) if @first_at < n0

    @first_at
  end

  def last_at=(last)

    @last_at =
      if last
        ldur = Rufus::Scheduler.parse_duration(last, no_error: true)
        (ldur && (EoTime.now + ldur)) || EoTime.make(last)
      else
        nil
      end

    fail ArgumentError.new(
      "cannot set last[_at|_in] in the past: " +
      "#{last.inspect} -> #{@last_at.inspect}"
    ) if last && @last_at < EoTime.now

    @last_at
  end

  def trigger(time)

    return if @paused_at
    #return set_next_time(time) if @paused_at

    return (@next_time = nil) if @times && @times < 1
    return (@next_time = nil) if @last_at && time >= @last_at
      #
      # It keeps jobs one step too much in @jobs, but it's OK

    super

    @times -= 1 if @times
  end

  def pause

    @paused_at = EoTime.now
  end

  def resume(opts={})

    @resume_discard_past = opts[:discard_past]
    @paused_at = nil
  end

  def paused?

    !! @paused_at
  end

  def determine_id

    [
      self.class.name.split(':').last.downcase[0..-4],
      @scheduled_at.to_f,
      (self.object_id < 0 ? 'm' : '') + self.object_id.to_s
    ].map(&:to_s).join('_')
  end

  def occurrences(time0, time1)

    a = []

    nt = @next_time
    ts = @times

    loop do

      break if nt > time1
      break if ts && ts <= 0

      a << nt if nt >= time0

      nt = next_time_from(nt)
      ts = ts - 1 if ts
    end

    a
  end

  # Starting from now, returns the {count} next occurences
  # (EtOrbi::EoTime instances) for this job.
  #
  # Warning, for IntervalJob, the @mean_work_time is used since
  # "interval" works from the end of a job to its next trigger
  # (not from one trigger to the next, as for "cron" and "every").
  #
  def next_times(count)

    (count - 1).times.inject([ next_time ]) { |a|
      a << next_time_from(a.last)
      a }
  end
end

#
# A parent class of EveryJob and IntervalJob
#
class Rufus::Scheduler::EvInJob < Rufus::Scheduler::RepeatJob

  def first_at=(first)

    @next_time = super
  end
end

class Rufus::Scheduler::EveryJob < Rufus::Scheduler::EvInJob

  attr_reader :frequency

  attr_accessor :resume_discard_past

  def initialize(scheduler, duration, opts, block)

    super(scheduler, duration, opts, block)

    @frequency = Rufus::Scheduler.parse_in(@original)

    fail ArgumentError.new(
      "cannot schedule #{self.class} with a frequency " +
      "of #{@frequency.inspect} (#{@original.inspect})"
    ) if @frequency <= 0

    set_next_time(nil)
  end

  def check_frequency

    fail ArgumentError.new(
     "job frequency (#{@frequency}s) is higher than " +
     "scheduler frequency (#{@scheduler.frequency}s)"
    ) if @frequency < @scheduler.frequency
  end

  def next_time_from(time)

    time + @frequency
  end

  protected

  def set_next_time(trigger_time, is_post=false, now=nil)

    return if is_post

    n = now || EoTime.now

    return @next_time = @first_at \
      if @first_at && (trigger_time == nil || @first_at > n)

    dp = discard_past?

    loop do

      @next_time = (@next_time || n) + @frequency

      break if dp == false
      break if @next_time > n
    end
  end
end

class Rufus::Scheduler::IntervalJob < Rufus::Scheduler::EvInJob

  attr_reader :interval

  def initialize(scheduler, interval, opts, block)

    super(scheduler, interval, opts, block)

    @interval = Rufus::Scheduler.parse_in(@original)

    fail ArgumentError.new(
      "cannot schedule #{self.class} with an interval " +
      "of #{@interval.inspect} (#{@original.inspect})"
    ) if @interval <= 0

    set_next_time(nil)
  end

  def next_time_from(time)

    time + @mean_work_time + @interval
  end

  protected

  def set_next_time(trigger_time, is_post=false, now=nil)

    n = now || EoTime.now

    @next_time =
      if is_post
        n + @interval
      elsif trigger_time.nil?
        if @first_at == nil || @first_at < n
          n + @interval
        else
          @first_at
        end
      else
        false
      end
  end
end

class Rufus::Scheduler::CronJob < Rufus::Scheduler::RepeatJob

  attr_reader :cron_line

  def initialize(scheduler, cronline, opts, block)

    super(scheduler, cronline, opts, block)

    @cron_line = opts[:_t] || ::Fugit::Cron.do_parse(cronline)

    set_next_time(nil)
  end

  def check_frequency

    return if @scheduler.frequency <= 1
      #
      # The minimum time delta in a cron job is 1 second, so if the
      # scheduler frequency is less than that, no worries.

    f = @cron_line.rough_frequency

    fail ArgumentError.new(
     "job frequency (min ~#{f}s) is higher than " +
     "scheduler frequency (#{@scheduler.frequency}s)"
    ) if f < @scheduler.frequency
  end

  def brute_frequency

    @cron_line.brute_frequency
  end

  def rough_frequency

    @cron_line.rough_frequency
  end

  def next_time_from(time)

    @cron_line.next_time(time)
  end

  protected

  def set_next_time(trigger_time, is_post=false, now=nil)

    return if is_post

    t = trigger_time || now || EoTime.now

    previous = @previous_time || @scheduled_at
    t = previous if ! discard_past? && t > previous

    @next_time =
      if @first_at && @first_at > t
        @first_at
      else
        @cron_line.next_time(t)
      end
  end
end
