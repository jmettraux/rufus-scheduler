
#
# Specifying rufus-scheduler
#
# Fri Aug  9 07:10:18 JST 2013
#

require 'spec_helper'


describe Rufus::Scheduler do

  before :each do

    @taoe = Thread.abort_on_exception
    Thread.abort_on_exception = false

    @ose = $stderr
    $stderr = StringIO.new

    @scheduler = Rufus::Scheduler.new
  end

  after :each do

    @scheduler.shutdown

    Thread.abort_on_exception = @taoe

    $stderr = @ose
  end

  context 'error in block' do

    it 'intercepts the error and describes it on $stderr' do

      counter = 0

      @scheduler.every('0.5s') do
        counter += 1
        fail 'argh'
      end

      sleep 2

      counter.should > 2
      $stderr.string.should match(/argh/)
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

    it 'intercepts the error and describes it on $stderr' do

      mfh = MyFailingHandler.new

      @scheduler.every('0.5s', mfh)

      sleep 2

      mfh.counter.should > 2
      $stderr.string.should match(/ouch/)
    end
  end

  context 'Rufus::Scheduler#stderr=' do

    it 'lets divert error information to custom files' do

      @scheduler.stderr = StringIO.new

      @scheduler.in('0s') do
        fail 'miserably'
      end

      sleep 0.5

      @scheduler.stderr.string.should match(/intercepted an error/)
      @scheduler.stderr.string.should match(/miserably/)
    end
  end

  context 'Rufus::Scheduler#on_error(&block)' do

    it 'intercepts all StandardError instances' do

      $message = nil

      def @scheduler.on_error(job, err)
        $message = "#{job.class} #{job.original} #{err.message}"
      rescue
        p $!
      end

      @scheduler.in('0s') do
        fail 'miserably'
      end

      sleep 0.5

      $message.should == 'Rufus::Scheduler::InJob 0s miserably'
    end
  end
end

