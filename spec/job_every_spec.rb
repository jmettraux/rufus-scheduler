
#
# Specifying rufus-scheduler
#
# Wed Apr 17 06:00:59 JST 2013
#

require 'spec_helper'


describe Rufus::Scheduler::EveryJob do

  before :each do
    @scheduler = Rufus::Scheduler.new
  end
  after :each do
    @scheduler.shutdown
  end

  it 'triggers as expected' do

    counter = 0

    @scheduler.every '1s' do
      counter = counter + 1
    end

    sleep 3.5

    counter.should == 2
  end

  context 'first_at/in' do

    it 'triggers for the first time at first_at' do

      t = Time.now

      job = @scheduler.schedule_every '3s', :first_in => '1s' do; end

      sleep 2

      #p [ t, t.to_f ]
      #p [ job.last_time, job.last_time.to_f ]
      #p [ job.first_at, job.first_at.to_f ]

      job.first_at.should be_within_1s_of(t + 2)
      job.last_time.should be_within_1s_of(job.first_at)
    end
  end
end

