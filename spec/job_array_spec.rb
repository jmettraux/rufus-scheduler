
#
# Specifying rufus-scheduler
#
# Wed Apr 17 06:00:59 JST 2013
#

require 'spec_helper'


describe Rufus::Scheduler::JobArray do

  class DummyJob < Struct.new(:id, :next_time); end

  before(:each) do
    @array = Rufus::Scheduler::JobArray.new
  end

  describe '#push' do

    it 'pushes jobs' do

      @array.push(DummyJob.new('a', Time.local(0)))

      @array.to_a.collect(&:id).should == %w[ a ]
    end

    it 'pushes jobs and preserve their next_time order' do

      @array.push(DummyJob.new('a', Time.local(0)))
      @array.push(DummyJob.new('c', Time.local(2)))
      @array.push(DummyJob.new('b', Time.local(1)))

      @array.to_a.collect(&:id).should == %w[ a b c ]
    end

    it 'pushes jobs and preserve their next_time order (2)' do

      @array.push(DummyJob.new('a', Time.local(0)))
      @array.push(DummyJob.new('b', Time.local(1)))
      @array.push(DummyJob.new('d', Time.local(3)))
      @array.push(DummyJob.new('e', Time.local(4)))

      @array.push(DummyJob.new('c', Time.local(2)))

      @array.to_a.collect(&:id).should == %w[ a b c d e ]
    end
  end

  describe '#concat' do

    it 'accepts an empty array' do

      @array.push(DummyJob.new('c', Time.local(2)))

      @array.concat([])

      @array.to_a.collect(&:id).should == %w[ c ]
    end

    it 'pushes jobs and ensures next_time order' do

      @array.push(DummyJob.new('c', Time.local(2)))

      @array.concat([
        DummyJob.new('a', Time.local(0)),
        DummyJob.new('b', Time.local(1))
      ])

      @array.to_a.collect(&:id).should == %w[ a b c ]
    end
  end

  describe '#shift(now)' do

    it 'returns nil if there is no next job' do

      @array.shift(Time.local(0)).should == nil
    end

    it 'returns nil if there is no next job (2)' do

      @array.push(DummyJob.new('c', Time.local(2)))

      @array.shift(Time.local(1)).should == nil
    end

    it 'returns the next job if job.next_time <= now' do

      @array.push(DummyJob.new('a', Time.local(0)))

      @array.shift(Time.local(0)).class.should == DummyJob
    end
  end
end

