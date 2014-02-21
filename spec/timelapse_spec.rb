#
# Specifying rufus-scheduler
#
# Fri Feb 21 04:43:51 CST 2014
#

require 'spec_helper'

describe Rufus::Scheduler do

  describe '#initialize' do

    it 'accepts a :timelapse => Range option' do
      scheduler = Rufus::Scheduler.new(:timelapse => Time.now..(Time.now+60))
      scheduler.timelapse.should be_a Range
    end

    it 'allows :timelapse to be nil' do
      scheduler = Rufus::Scheduler.new(:timelapse => nil)
      scheduler.timelapse.should be_nil
    end

    it 'raises if the :timelapse value is not a Range' do
      lambda {
        scheduler = Rufus::Scheduler.new(:timelapse => 1)
      }.should raise_error(ArgumentError)
    end

    it 'raises if the :timelapse Range does not contain Times' do
      lambda {
        scheduler = Rufus::Scheduler.new(:timelapse => 1..2)
      }.should raise_error(ArgumentError)
    end

  end

  describe '#join' do

    it 'runs all scheduled jobs without delay if :timelapse option is given' do
      Thread.should_not_receive(:new)
      scheduler = Rufus::Scheduler.new(:timelapse => Time.now..(Time.now+60))
      scheduler.join
    end

    it 'runs only the jobs that fall within the :timelapse time range' do
      scheduler = Rufus::Scheduler.new(:timelapse => (Time.now+60)..(Time.now+120))

      @early_job = 0
      @correct_job = 0
      @late_job = 0
      @repeated_job = 0
      @at_job = 0

      scheduler.in '10s' do
        @early_job += 1
      end

      scheduler.in '75s' do
        @correct_job += 1
      end

      scheduler.in '300s' do
        @late_job += 1
      end

      scheduler.at "#{Time.now+75}" do
        @at_job += 1
      end

      scheduler.every '30s' do
        @repeated_job += 1
      end

      scheduler.join

      @early_job.should == 0
      @correct_job.should == 1
      @late_job.should == 0
      @at_job.should == 1
      @repeated_job.should == 2
    end

  end
end
