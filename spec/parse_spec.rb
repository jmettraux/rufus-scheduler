
require 'spec_helper'


describe Rufus::Scheduler do

  describe '.parse' do
  end

  describe '.parse_time_string' do

    def pds(s)
      Rufus::Scheduler.parse_duration_string(s)
    end

    it 'parses duration strings' do

      pds('-1.0d1.0w1.0d').should == -777600.0
      pds('-1d1w1d').should == -777600.0
      pds('-1w2d').should == -777600.0
      pds('-1h10s').should == -3610.0
      pds('-1h').should == -3600.0
      pds('-5.').should == -5.0
      pds('-2.5s').should == -2.5
      pds('-1s').should == -1.0
      pds('-500').should == -0.5
      pds('').should == 0.0
      pds('5.0').should == 5.0
      pds('0.5').should == 0.5
      pds('.5').should == 0.5
      pds('5.').should == 5.0
      pds('500').should == 0.5
      pds('1000').should == 1.0
      pds('1').should == 0.001
      pds('1s').should == 1.0
      pds('2.5s').should == 2.5
      pds('1h').should == 3600.0
      pds('1h10s').should == 3610.0
      pds('1w2d').should == 777600.0
      pds('1d1w1d').should == 777600.0
      pds('1.0d1.0w1.0d').should == 777600.0

      pds('.5m').should == 30.0
      pds('5.m').should == 300.0
      pds('1m.5s').should == 60.5
      pds('-.5m').should == -30.0
    end

    it 'raises on wrong duration strings' do

      lambda { pds('-') }.should raise_error(ArgumentError)
      lambda { pds('h') }.should raise_error(ArgumentError)
      lambda { pds('whatever') }.should raise_error(ArgumentError)
      lambda { pds('hms') }.should raise_error(ArgumentError)

      lambda { pds(' 1h ') }.should raise_error(ArgumentError)
    end
  end
end

