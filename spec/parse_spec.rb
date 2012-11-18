
require 'spec_helper'


describe Rufus::Scheduler do

  describe '.parse' do

    def parse(s)
      Rufus::Scheduler.parse(s)
    end

    it 'parses duration strings' do

      parse('1.0d1.0w1.0d').should == 777600.0
    end

    it 'parses datetimes' do

      parse('Sun Nov 18 16:01:00 JST 2012').to_s.should ==
        '2012-11-18 16:01:00 +0900'
    end

    it 'parses cronlines'

    it 'raises on unparseable input' do

      lambda {
        parse('nada')
      }.should raise_error(ArgumentError, 'no time information in "nada"')
    end
  end

  describe '.parse_time_string' do

    def pd(s)
      Rufus::Scheduler.parse_duration(s)
    end

    it 'parses duration strings' do

      pd('-1.0d1.0w1.0d').should == -777600.0
      pd('-1d1w1d').should == -777600.0
      pd('-1w2d').should == -777600.0
      pd('-1h10s').should == -3610.0
      pd('-1h').should == -3600.0
      pd('-5.').should == -5.0
      pd('-2.5s').should == -2.5
      pd('-1s').should == -1.0
      pd('-500').should == -0.5
      pd('').should == 0.0
      pd('5.0').should == 5.0
      pd('0.5').should == 0.5
      pd('.5').should == 0.5
      pd('5.').should == 5.0
      pd('500').should == 0.5
      pd('1000').should == 1.0
      pd('1').should == 0.001
      pd('1s').should == 1.0
      pd('2.5s').should == 2.5
      pd('1h').should == 3600.0
      pd('1h10s').should == 3610.0
      pd('1w2d').should == 777600.0
      pd('1d1w1d').should == 777600.0
      pd('1.0d1.0w1.0d').should == 777600.0

      pd('.5m').should == 30.0
      pd('5.m').should == 300.0
      pd('1m.5s').should == 60.5
      pd('-.5m').should == -30.0
    end

    it 'raises on wrong duration strings' do

      lambda { pd('-') }.should raise_error(ArgumentError)
      lambda { pd('h') }.should raise_error(ArgumentError)
      lambda { pd('whatever') }.should raise_error(ArgumentError)
      lambda { pd('hms') }.should raise_error(ArgumentError)

      lambda { pd(' 1h ') }.should raise_error(ArgumentError)
    end
  end
end

