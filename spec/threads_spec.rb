
#
# Specifying rufus-scheduler
#
# Thu Jul 25 05:53:51 JST 2013
#

require 'spec_helper'


describe Rufus::Scheduler do

  before :each do
    @scheduler = Rufus::Scheduler.new
  end
  after :each do
    @scheduler.shutdown
  end

  context 'thread pool' do

    it 'starts with an empty thread pool' do

      @scheduler.job_threads.size.should == 0
    end

    it 'does not cross the max_job_threads threshold' do

      @scheduler.min_job_threads = 2
      @scheduler.max_job_threads = 5

      10.times do
        @scheduler.in '0s' do
          sleep 5
        end
      end

      sleep 0.5

      #@scheduler.job_threads.each do |t|
      #  p t.keys
      #  p t[:rufus_scheduler_job].class
      #end

      @scheduler.job_threads.size.should == 5
    end
  end
end

