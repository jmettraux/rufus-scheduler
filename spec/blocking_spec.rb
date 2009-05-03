
#
# Specifying rufus-scheduler
#
# Sat Mar 21 17:36:36 JST 2009
#

require File.dirname(__FILE__) + '/spec_base'


describe SCHEDULER_CLASS do

  before do
    @s = start_scheduler
  end
  after do
    stop_scheduler(@s)
  end

  JOB = Proc.new do |x|
    begin
      $var << "a#{x}"
      sleep 0.500
      $var << "b#{x}"
    rescue Exception => e
      puts '=' * 80
      p e
      puts '=' * 80
    end
  end

  it 'should not block when :blocking => nil' do

    $var = []
    @s.in('1s') { JOB.call(1) }
    @s.in('1s') { JOB.call(2) }

    sleep 5.0

    [ %w{ a1 a2 b1 b2 }, %w{ a1 a2 b2 b1 } ].should.include($var)
  end

  it 'should block when :blocking => true' do

    $var = []
    @s.in('1s', :blocking => true) { JOB.call(8) }
    @s.in('1s', :blocking => true) { JOB.call(9) }

    sleep 4.5

    $var.should.equal(%w{ a8 b8 a9 b9 })
  end
end

