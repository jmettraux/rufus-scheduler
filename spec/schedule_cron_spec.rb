
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
      }.to raise_error(ArgumentError)
    end
  end

  describe '#schedule_cron' do

    it 'returns a CronJob instance' do

      job = @scheduler.schedule_cron '* * * * *' do; end

      expect(job.class).to eq(Rufus::Scheduler::CronJob)
      expect(job.original).to eq('* * * * *')
      expect(job.job_id).to match(/^cron_/)
    end
  end

  describe '#timeline' do
    it 'should not lock when running timeline with a time_at specified' do
      now = Time.now

      # Scheduling a cron job with a first_at and running #timeline use
      # to result in an infinite loop.
      @scheduler.cron('* * * * * *', first_at: now + 3) {}

      jobs = @scheduler.timeline(now, now + 4)
      expect(jobs.size).to be 2
      expect(jobs[0][0]).to be_within_1s_of now + 3
      expect(jobs[1][0]).to be_within_1s_of now + 4
    end
  end
end

