
#
# Specifying rufus-scheduler
#
# Fri Mar 20 23:46:32 JST 2009
#

require 'spec_base'


describe 'rufus/rtime' do

  def pts(s)
    Rufus.parse_time_string(s)
  end

  def tts(f, opts={})
    Rufus.to_time_string(f, opts)
  end

  def tdh(f, opts={})
    Rufus.to_duration_hash(f, opts)
  end

  it 'parses duration strings' do

    pts('-1.0d1.0w1.0d').should == -777600.0
    pts('-1d1w1d').should == -777600.0
    pts('-1w2d').should == -777600.0
    pts('-1h10s').should == -3610.0
    pts('-1h').should == -3600.0
    pts('-5.').should == -5.0
    pts('-2.5s').should == -2.5
    pts('-1s').should == -1.0
    pts('-500').should == -0.5
    pts('').should == 0.0
    pts('5.0').should == 5.0
    pts('0.5').should == 0.5
    pts('.5').should == 0.5
    pts('5.').should == 5.0
    pts('500').should == 0.5
    pts('1000').should == 1.0
    pts('1').should == 0.001
    pts('1s').should == 1.0
    pts('2.5s').should == 2.5
    pts('1h').should == 3600.0
    pts('1h10s').should == 3610.0
    pts('1w2d').should == 777600.0
    pts('1d1w1d').should == 777600.0
    pts('1.0d1.0w1.0d').should == 777600.0

    pts('.5m').should == 30.0
    pts('5.m').should == 300.0
    pts('1m.5s').should == 60.5
    pts('-.5m').should == -30.0
  end

  it 'raises on wrong duration strings' do

    lambda { pts('-') }.should raise_error(ArgumentError)
    lambda { pts('h') }.should raise_error(ArgumentError)
    lambda { pts('whatever') }.should raise_error(ArgumentError)
    lambda { pts('hms') }.should raise_error(ArgumentError)

    lambda { pts(' 1h ') }.should raise_error(ArgumentError)
  end

  it 'generates duration strings' do

    tts(0).should == '0s'
    tts(0, :drop_seconds => true).should == '0m'
    tts(60).should == '1m'
    tts(61).should == '1m1s'
    tts(3661).should == '1h1m1s'
    tts(24 * 3600).should == '1d'
    tts(7 * 24 * 3600 + 1).should == '1w1s'
    tts(30 * 24 * 3600 + 1).should == '4w2d1s'
    tts(30 * 24 * 3600 + 1, :months => true).should == '1M1s'
  end

  it 'computes duration hashes' do

    tdh(0).should == {}
    tdh(0.128).should == { :ms => 128 }
    tdh(60.127).should == { :m => 1, :ms => 127 }
    tdh(61.127).should == { :m => 1, :s => 1, :ms => 127 }
    tdh(61.127, :drop_seconds => true).should == { :m => 1 }
  end
end

describe 'rufus/rtime#at_to_f' do

  def atf(o)
    Rufus.at_to_f(o)
  end

  it 'turns Time at values to float' do

    t = Time.now
    tf = t.to_f.to_i.to_f

    atf(t + 2).to_i.to_f.should == tf + 2
  end

  it 'turns String at values to float' do

    atf('Sat Mar 21 20:08:01 +0900 2009').should == 1237633681.0
    atf('Sat Mar 21 20:08:01 -0900 2009').should == 1237698481.0
    atf('Sat Mar 21 20:08:01 +0000 2009').should == 1237666081.0
    atf('Sat Mar 21 20:08:01 2009').should == 1237666081.0
    atf('Mar 21 20:08:01 2009').should == 1237666081.0
    atf('2009/03/21 20:08').should == 1237666080.0
  end

  it 'accepts integers' do

    atf(1).should == 1.0
  end
end

