
#
# Specifying rufus-scheduler-em
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
    end

    it 'should set the scheduler thread name' do
      s = start_scheduler(:thread_name => 'nada')
      s.instance_variable_get(:@thread)['name'].should.equal('nada')
    end
  end

end

