
#
# Specifying rufus-scheduler
#
# Wed Apr 17 06:00:59 JST 2013
#

require 'spec_helper'


describe Rufus::Scheduler::IntervalJob do

  before :each do
    @scheduler = Rufus::Scheduler.new
  end
  after :each do
    @scheduler.shutdown
  end

  describe '#interval' do

    it 'returns the scheduled interval' do

      job = @scheduler.schedule_interval('1h') do; end

      job.interval.should == 3600
    end
  end
end

