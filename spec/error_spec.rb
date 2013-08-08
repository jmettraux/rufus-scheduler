
#
# Specifying rufus-scheduler
#
# Fri Aug  9 07:10:18 JST 2013
#

require 'spec_helper'


describe Rufus::Scheduler::Job do

  before :each do

    @taoe = Thread.abort_on_exception
    Thread.abort_on_exception = false

    @scheduler = Rufus::Scheduler.new
  end

  after :each do

    @scheduler.shutdown

    Thread.abort_on_exception = @taoe
  end

  context 'error in block' do

    it 'discards the error silently' do

      counter = 0

      @scheduler.every('0.5s') do
        counter += 1
        fail 'argh'
      end

      sleep 2

      counter.should > 2
    end
  end

  context 'error in callable' do

    class MyFailingHandler
      attr_reader :counter
      def initialize
        @counter = 0
      end
      def call(job, time)
        @counter = @counter + 1
        fail 'ouch'
      end
    end

    it 'discards the error silently' do

      mfh = MyFailingHandler.new

      @scheduler.every('0.5s', mfh)

      sleep 2

      mfh.counter.should > 2
    end
  end

  context 'Rufus::Scheduler#on_error(&block)' do

    it 'intercepts all StandardError instances'
  end
end

