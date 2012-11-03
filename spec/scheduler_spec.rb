
require 'spec_helper'


describe Rufus::Scheduler do

  describe '#initialize' do

    it 'starts the scheduler thread'

    it 'accepts a :frequency option'
  end

  describe '#uptime' do

    it 'returns the uptime as a float' do

      scheduler = Rufus::Scheduler.new

      scheduler.uptime.should > 0.0
    end
  end

  describe '#uptime_s' do

    it 'returns the uptime as a human readable string'
  end

  describe '#shutdown' do

    it 'blanks the uptime' do

      scheduler = Rufus::Scheduler.new
      scheduler.shutdown

      scheduler.uptime.should == nil
    end

    it 'terminates the scheduler'
    it 'has a #stop alias'
    it 'has a #close alias ???'
  end

  describe '#pause' do
  end
  describe '#resume' do
  end

  describe '#jobs' do
  end
  describe '#every_jobs' do
  end
  describe '#at_jobs' do
  end
  describe '#in_jobs' do
  end
  describe '#cron_jobs' do
  end
end

