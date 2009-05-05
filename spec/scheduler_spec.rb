
#
# Specifying rufus-scheduler
#
# Sat Mar 21 17:43:23 JST 2009
#

require File.dirname(__FILE__) + '/spec_base'


describe SCHEDULER_CLASS do

  it 'should stop' do

    var = nil

    s = start_scheduler
    s.in('3s') { var = true }

    stop_scheduler(s)

    var.should.be.nil
    sleep 4
    var.should.be.nil
  end

  unless SCHEDULER_CLASS == Rufus::Scheduler::EmScheduler

    it 'should set a default scheduler thread name' do

      s = start_scheduler

      s.instance_variable_get(:@thread)['name'].should.match(
        /Rufus::Scheduler::.*Scheduler - \d+\.\d+\.\d+/)

      stop_scheduler(s)
    end

    it 'should set the scheduler thread name' do

      s = start_scheduler(:thread_name => 'nada')
      s.instance_variable_get(:@thread)['name'].should.equal('nada')

      stop_scheduler(s)
    end
  end

  it 'should accept a custom frequency' do

    var = nil

    s = start_scheduler(:frequency => 3.0)

    s.in('1s') { var = true }

    sleep 1
    var.should.be.nil

    sleep 1
    var.should.be.nil

    sleep 2
    var.should.be.true

    stop_scheduler(s)
  end

end

describe 'Rufus::Scheduler#start_new' do

  it 'should piggyback EM if present and running' do

    s = Rufus::Scheduler.start_new

    s.class.should.equal(SCHEDULER_CLASS)

    stop_scheduler(s)
  end
end

