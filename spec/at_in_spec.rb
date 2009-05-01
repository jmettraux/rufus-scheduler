
#
# Specifying rufus-scheduler-em
#
# Sun Mar 22 16:47:28 JST 2009
#

require File.dirname(__FILE__) + '/spec_base'


describe SCHEDULER_CLASS do

  before do
    @s = start_scheduler
  end
  after do
    stop_scheduler(@s)
  end


  it 'should override jobs with the same id' do

    hits = []

    job0 = @s.in '1s', :job_id => 'nada' do
      hits << 0
    end

    wait_next_tick

    job1 = @s.in '1s', :job_id => 'nada' do
      hits << 1
    end

    wait_next_tick
    @s.jobs.size.should.equal(1)

    hits.should.be.empty

    sleep 1.5

    hits.should.equal([ 1 ])

    @s.jobs.size.should.equal(0)
  end

end

