
#
# Specifying rufus-scheduler
#
# Tue May  5 14:47:16 JST 2009
#

require 'spec_base'


describe Rufus::Scheduler::Schedulable do

  before(:each) do
    @s = start_scheduler
  end
  after(:each) do
    stop_scheduler(@s)
  end

  class JobAlpha
    attr_reader :value
    def trigger(params)
      @value = params
    end
  end
  class JobBravo
    attr_reader :value
    def call(job)
      @value = job
    end
  end

  it 'schedules via :schedulable' do

    j = JobAlpha.new

    @s.in '1s', :schedulable => j

    sleep 1.4

    j.value.class.should == Hash
    j.value[:job].class.should == Rufus::Scheduler::InJob
  end

  it 'honours schedulables that reply to :call' do

    j = JobBravo.new

    @s.in '1s', :schedulable => j

    sleep 1.4

    j.value.class.should == Rufus::Scheduler::InJob
  end

  it 'accepts trigger schedulables as second param' do

    j = JobAlpha.new

    @s.in '1s', j

    sleep 1.4

    j.value.class.should == Hash
    j.value[:job].class.should == Rufus::Scheduler::InJob
  end

  it 'accepts call schedulables as second param' do

    j = JobBravo.new

    @s.in '1s', j

    sleep 1.4

    j.value.class.should == Rufus::Scheduler::InJob
  end

  class MySchedulable
    def self.job
      @@job
    end
    def self.call(job)
      @@job = job
    end
  end

  it 'accepts schedulable classes as second param' do

    @s.in '1s', MySchedulable

    sleep 1.4

    MySchedulable.job.class.should == Rufus::Scheduler::InJob
  end
end

