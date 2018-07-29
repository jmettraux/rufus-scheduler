
#
# Specifying rufus-scheduler
#
# Sat Jul 13 04:52:08 JST 2013
#
# In the train between Bern and Fribourg, riding back
# from the @ruvetia drinkup
#

require 'spec_helper'


describe Rufus::Scheduler do

  before :each do
    @scheduler = Rufus::Scheduler.new
  end
  after :each do
    @scheduler.shutdown
  end

  describe '#cron' do

    it 'schedules' do

      counter = 0

      sleep_until_next_second
      sleep 0.3 # make sure to schedule right after a scheduler 'tick'

      job =
        @scheduler.cron '* * * * * *', :job => true do
          counter = counter + 1
        end

      sleep_until_next_second
      sleep_until_next_second
      sleep 0.3 # be sure to be well into the second

      expect(counter).to eq(2)
    end

    it 'raises if the job frequency is higher than the scheduler frequency' do

      @scheduler.frequency = 10

      expect {
        @scheduler.cron '* * * * * *' do; end
      }.to raise_error(
        ArgumentError,
        'job frequency (min ~1s) is higher than scheduler frequency (10s)'
      )
    end

    it 'accepts a CronLine instance' do

      cl = Fugit.parse('* * * * *')
      job_id = @scheduler.cron(cl) {}
      job = @scheduler.job(job_id)

      expect(job.cron_line.object_id).to eq(cl.object_id)
    end

    it 'is not slow handling frequent cron durations' do
      @scheduler.frequency = 10

      s = Time.now

      @scheduler.cron '*/15 * * * * *' do; end

      expect(Time.now - s).to be < 1
    end

    it 'is not slow handling non-frequent cron durations' do
      @scheduler.frequency = 10

      s = Time.now

      @scheduler.cron '31 18 18 10 *' do; end

      expect(Time.now - s).to be < 1
    end
  end

  describe '#schedule_cron' do

    it 'returns a CronJob instance' do

      job = @scheduler.schedule_cron '* * * * *' do; end

      expect(job.class).to eq(Rufus::Scheduler::CronJob)
      expect(job.original).to eq('* * * * *')
      expect(job.job_id).to match(/^cron_/)
    end

    it 'accepts a CronLine instance' do

      cl = Fugit.parse('* * * * *')
      job = @scheduler.schedule_cron(cl) {}

      expect(job.cron_line.object_id).to eq(cl.object_id)
    end
  end
end
