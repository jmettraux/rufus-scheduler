
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

      job =
        @scheduler.cron '* * * * * *', :job => true do
          counter = counter + 1
        end

      sleep 3.5

      counter.should > 2
    end
  end

  describe '#schedule_cron' do

    it 'returns a CronJob instance' do

      job = @scheduler.schedule_cron '* * * * *' do; end

      job.class.should == Rufus::Scheduler::CronJob
      job.original.should == '* * * * *'
      job.job_id.should match(/^cron_/)
    end
  end
end

describe Rufus::Scheduler::CronJob do

  it 'works'
end

