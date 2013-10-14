
#
# Specifying rufus-scheduler
#
# Wed Apr 17 06:00:59 JST 2013
#

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

      # local

      parse('Sun Nov 18 16:01:00 2012').strftime('%c').should ==
        'Sun Nov 18 16:01:00 2012'
    end

    it 'parses datetimes with timezones' do

      parse('Sun Nov 18 16:01:00 2012 Japan').getutc.strftime('%c').should ==
        'Sun Nov 18 07:01:00 2012'

      parse('Sun Nov 18 16:01:00 2012 Zulu').getutc.strftime('%c').should ==
        'Sun Nov 18 16:01:00 2012'

      parse('Sun Nov 18 16:01:00 Japan 2012').getutc.strftime('%c').should ==
        'Sun Nov 18 07:01:00 2012'

      parse('Japan Sun Nov 18 16:01:00 2012').getutc.strftime('%c').should ==
        'Sun Nov 18 07:01:00 2012'
    end

    it 'parses datetimes with named timezones' do

      parse(
        'Sun Nov 18 16:01:00 2012 Europe/Berlin'
      ).strftime('%c %z').should ==
        'Sun Nov 18 15:01:00 2012 +0000'
    end

    it 'parses datetimes (with the local timezone implicitely)' do

      localzone = Time.now.strftime('%z')

      parse('Sun Nov 18 16:01:00 2012').strftime('%c %z').should ==
        "Sun Nov 18 16:01:00 2012 #{localzone}"
    end

    it 'parses cronlines' do

      out = parse('* * * * *')

      out.class.should == Rufus::Scheduler::CronLine
      out.original.should == '* * * * *'

      parse('10 23 * * *').class.should == Rufus::Scheduler::CronLine
      parse('* 23 * * *').class.should == Rufus::Scheduler::CronLine
    end

    it 'raises on unparseable input' do

      lambda {
        parse('nada')
      }.should raise_error(ArgumentError, 'couldn\'t parse "nada"')
    end
  end

  describe '.parse_duration' do

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
      pd('-500').should == -500
      pd('').should == 0.0
      pd('5.0').should == 5.0
      pd('0.5').should == 0.5
      pd('.5').should == 0.5
      pd('5.').should == 5.0
      pd('500').should == 500
      pd('1000').should == 1000
      pd('1').should == 1.0
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

      pd('1').should == 1
      pd('0.1').should == 0.1
      pd('1s').should == 1
    end

    it 'calls #to_s on its input' do

      pd(0.1).should == 0.1
    end

    it 'raises on wrong duration strings' do

      lambda { pd('-') }.should raise_error(ArgumentError)
      lambda { pd('h') }.should raise_error(ArgumentError)
      lambda { pd('whatever') }.should raise_error(ArgumentError)
      lambda { pd('hms') }.should raise_error(ArgumentError)

      lambda { pd(' 1h ') }.should raise_error(ArgumentError)
    end
  end

  describe '.parse_time_string -> .parse_duration' do

    it 'is still around for libs using it out there' do

      Rufus::Scheduler.parse_time_string('1d1w1d').should == 777600.0
    end
  end

  describe '.parse_duration_string -> .parse_duration' do

    it 'is still around for libs using it out there' do

      Rufus::Scheduler.parse_duration_string('1d1w1d').should == 777600.0
    end
  end

  describe '.to_duration' do

    def td(o, opts={})
      Rufus::Scheduler.to_duration(o, opts)
    end

    it 'turns integers into duration strings' do

      td(0).should == '0s'
      td(60).should == '1m'
      td(61).should == '1m1s'
      td(3661).should == '1h1m1s'
      td(24 * 3600).should == '1d'
      td(7 * 24 * 3600 + 1).should == '1w1s'
      td(30 * 24 * 3600 + 1).should == '4w2d1s'
    end

    it 'ignores seconds and milliseconds if :drop_seconds => true' do

      td(0, :drop_seconds => true).should == '0m'
      td(5, :drop_seconds => true).should == '0m'
      td(61, :drop_seconds => true).should == '1m'
    end

    it 'displays months if :months => true' do

      td(1, :months => true).should == '1s'
      td(30 * 24 * 3600 + 1, :months => true).should == '1M1s'
    end

    it 'turns floats into duration strings' do

      td(0.1).should == '100'
      td(1.1).should == '1s100'
    end
  end

  describe '.to_duration_hash' do

    def tdh(o, opts={})
      Rufus::Scheduler.to_duration_hash(o, opts)
    end

    it 'turns integers duration hashes' do

      tdh(0).should == {}
      tdh(60).should == { :m => 1 }
    end

    it 'turns floats duration hashes' do

      tdh(0.128).should == { :ms => 128 }
      tdh(60.127).should == { :m => 1, :ms => 127 }
    end

    it 'drops seconds and milliseconds if :drop_seconds => true' do

      tdh(61.127).should == { :m => 1, :s => 1, :ms => 127 }
      tdh(61.127, :drop_seconds => true).should == { :m => 1 }
    end
  end
end

