
class Rufus::Scheduler::OneTimeJob < Rufus::Scheduler::Job

  alias time next_time

  def occurrences(time0, time1)

    (time >= time0 && time <= time1) ? [ time ] : []
  end

  # Used when discard_past? is set to true or :fail at scheduler or job level...
  #
  def past?

    @next_time &&
    @next_time < Time.now - @scheduler.frequency
  end

  protected

  def determine_id

    [
      self.class.name.split(':').last.downcase[0..-4],
      @scheduled_at.to_f,
      @next_time.to_f,
      (self.object_id < 0 ? 'm' : '') + self.object_id.to_s
    ].map(&:to_s).join('_')
  end

  # There is no "next time" for one time jobs, hence the false.
  #
  def set_next_time(trigger_time, is_post=false, now=nil)

    @next_time = is_post ? nil : false
  end
end

class Rufus::Scheduler::AtJob < Rufus::Scheduler::OneTimeJob

  def initialize(scheduler, time, opts, block)

    super(scheduler, time, opts, block)

    @next_time =
      opts[:_t] || Rufus::Scheduler.parse_at(time, opts)
  end
end

class Rufus::Scheduler::InJob < Rufus::Scheduler::OneTimeJob

  def initialize(scheduler, duration, opts, block)

    super(scheduler, duration, opts, block)

    @next_time =
      @scheduled_at +
      opts[:_t] || Rufus::Scheduler.parse_in(duration, opts)
  end
end

