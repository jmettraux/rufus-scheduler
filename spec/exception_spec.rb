
#
# Specifying rufus-scheduler
#
# Mon May  4 17:07:17 JST 2009
#

require File.dirname(__FILE__) + '/spec_base'


describe SCHEDULER_CLASS do

  before do
    @s = start_scheduler
  end
  after do
    stop_scheduler(@s)
  end

  it 'should emit exception messages to stdout' do

    require 'stringio' unless defined?(StringIO) # ruby 1.9

    stdout = $stdout
    s = StringIO.new
    $stdout = s

    @s.in 0.100 do
      raise 'Houston we have a problem'
    end

    sleep 0.500
    $stdout = stdout

    s.close

    s.string.should.match(/Houston we have a problem/)
  end

  it 'should accept custom handling of exceptions' do

    $job = nil

    def @s.handle_exception (j, e)
      $job = j
    end

    @s.in 0.100 do
      raise 'Houston we have a problem'
    end

    sleep 0.500

    $job.class.should.equal(Rufus::Scheduler::InJob)
  end

  it 'should accept overriding #log_exception' do

    $e = nil

    def @s.log_exception (e)
      $e = e
    end

    @s.in 0.100 do
      raise 'Houston we have a problem'
    end

    sleep 0.500

    $e.to_s.should.equal('Houston we have a problem')
  end

end

