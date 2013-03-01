
#
# Specifying rufus-scheduler
#
# Sat Mar 21 17:36:36 JST 2009
#

require 'spec_base'


describe SCHEDULER_CLASS do

  before(:each) do
    @s = start_scheduler
  end
  after(:each) do
    stop_scheduler(@s)
  end

  JOB =
    Proc.new do |x|
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

  context ':blocking => nil' do

    it "doesn't block" do

      $var = []
      @s.in('1s') { JOB.call(1) }
      @s.in('1s') { JOB.call(2) }

      sleep 4.0

      [
        %w{ a1 a2 b1 b2 }, %w{ a1 a2 b2 b1 },
        %w{ a2 a1 b2 b1 }, %w{ a2 a1 b1 b2 }
      ].should include($var)
    end
  end

  context ':blocking => true' do

    it 'blocks' do

      $var = []
      @s.in('1s', :blocking => true) { JOB.call(8) }
      @s.in('1s', :blocking => true) { JOB.call(9) }

      sleep 4.5

      $var.should == %w[ a8 b8 a9 b9 ]
    end
  end
end

