
#
# Specifying rufus-scheduler
#
# Mon May  4 20:33:23 JST 2009
#

require File.dirname(__FILE__) + '/spec_base'


describe SCHEDULER_CLASS do

  before do
    @s = start_scheduler
  end
  after do
    stop_scheduler(@s)
  end

  it 'should pass the job to the block' do

    job = nil

    @s.in 0.500 do |j|
      job = j
    end

    sleep 0.800

    job.class.should.equal(Rufus::Scheduler::InJob)
  end

end

describe "#{SCHEDULER_CLASS} with :onezero_block_arity => true" do

  before do
    @s = start_scheduler(:onezero_block_arity => true)
  end
  after do
    stop_scheduler(@s)
  end

  it 'should pass [ params ] when arity == 1' do

    job = @s.in 0.500 do |params|
      params[:seen] = true
    end

    sleep 0.800

    job.params[:seen].should.be.true
  end
end
