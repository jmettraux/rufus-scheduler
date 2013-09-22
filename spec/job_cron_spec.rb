
#
# Specifying rufus-scheduler
#
# Wed Apr 17 06:00:59 JST 2013
#

require 'spec_helper'


describe Rufus::Scheduler::CronJob do

  before :each do
    @scheduler = Rufus::Scheduler.new
  end
  after :each do
    @scheduler.shutdown
  end

  context 'normal' do

    it 'triggers near the zero second' do

      job = @scheduler.schedule_cron '* * * * *' do; end

      sleep_until_next_minute

      (job.last_time.to_i % 10).should == 0
    end
  end

  #context 'sub-minute' do
  #
  #  it 'triggers near the zero second' do
  #
  #    job = @scheduler.schedule_cron '* * * * * *' do; end
  #
  #    sleep 1.5
  #
  #    p job.last_time
  #    p job.last_time.to_f
  #  end
  #end

  context 'first_at/in' do

    it 'does not trigger before first_at is reached' do

      t = Time.now

      job =
        @scheduler.schedule_cron '* * * * * *', :first_in => '3s' do
          triggered = Time.now
        end

      sleep 1

      #p [ t, t.to_f ]
      #p [ job.last_time, job.last_time.to_f ]
      #p [ job.first_at, job.first_at.to_f ]

      job.first_at.should be_within_1s_of(t + 3)
      job.last_time.should == nil
    end
  end
end

