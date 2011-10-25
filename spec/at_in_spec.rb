
#
# Specifying rufus-scheduler
#
# Sun Mar 22 16:47:28 JST 2009
#

require 'spec_base'


describe SCHEDULER_CLASS do

  before(:each) do
    @s = start_scheduler
  end
  after(:each) do
    stop_scheduler(@s)
  end


  it 'overrides jobs with the same id' do

    hits = []

    job0 = @s.in '1s', :job_id => 'nada' do
      hits << 0
    end

    wait_next_tick

    job1 = @s.in '1s', :job_id => 'nada' do
      hits << 1
    end

    wait_next_tick
    @s.jobs.size.should == 1

    hits.should == []

    sleep 1.5

    hits.should == [ 1 ]

    @s.jobs.size.should == 0
  end
end

