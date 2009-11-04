
#
# Specifying rufus-scheduler
#
# Tue May  5 14:47:16 JST 2009
#

require File.dirname(__FILE__) + '/spec_base'


describe Rufus::Scheduler::Schedulable do

  before do
    @s = start_scheduler
  end
  after do
    stop_scheduler(@s)
  end

  class JobAlpha
    attr_reader :value
    def trigger (params)
      @value = params
    end
  end
  class JobBravo
    attr_reader :value
    def call (job)
      @value = job
    end
  end

  it 'should schedule via :schedulable' do

    j = JobAlpha.new

    @s.in '1s', :schedulable => j

    sleep 1.4

    j.value.class.should.equal(Hash)
    j.value[:job].class.should.equal(Rufus::Scheduler::InJob)
  end

  it 'should honour schedulables that reply to :call' do

    j = JobBravo.new

    @s.in '1s', :schedulable => j

    sleep 1.4

    j.value.class.should.equal(Rufus::Scheduler::InJob)
  end

  it 'should accept trigger schedulables as second param' do

    j = JobAlpha.new

    @s.in '1s', j

    sleep 1.4

    j.value.class.should.equal(Hash)
    j.value[:job].class.should.equal(Rufus::Scheduler::InJob)
  end

  it 'should accept call schedulables as second param' do

    j = JobBravo.new

    @s.in '1s', j

    sleep 1.4

    j.value.class.should.equal(Rufus::Scheduler::InJob)
  end
end

