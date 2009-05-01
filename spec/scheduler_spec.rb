
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

end

