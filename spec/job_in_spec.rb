
#
# Specifying rufus-scheduler
#
# Wed Apr 17 06:00:59 JST 2013
#

require 'spec_helper'


describe Rufus::Scheduler::InJob do

  before :each do
    @scheduler = Rufus::Scheduler.new
  end
  after :each do
    @scheduler.shutdown
  end

  describe '#next_times' do

    it 'returns the next n times' do

      job = @scheduler.schedule_in '5m' do; end

      expect(job.next_times(3)).to eq([ job.next_time ])
    end

    it 'returns an empty array if it already triggered' do

      job = @scheduler.schedule_in 0.001 do; end

      sleep 0.350

      expect(job.next_times(3)).to eq([])
    end
  end
end

