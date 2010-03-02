
#
# Specifying rufus-scheduler
#
# Fri Mar 20 23:46:32 JST 2009
#

require File.dirname(__FILE__) + '/spec_base'


describe 'rufus/otime' do

  def pts (s)
    Rufus.parse_time_string(s)
  end

  def tts (f, opts={})
    Rufus.to_time_string(f, opts)
  end

  def tdh (f, opts={})
    Rufus.to_duration_hash(f, opts)
  end

  it 'should parse duration strings' do

    pts('5.0').should.equal(5.0)
    pts('0.5').should.equal(0.5)
    pts('.5').should.equal(0.5)
    pts('5.').should.equal(5.0)
    pts('500').should.equal(0.5)
    pts('1000').should.equal(1.0)
    pts('1').should.equal(0.001)
    pts('1s').should.equal(1.0)
    pts('1h').should.equal(3600.0)
    pts('1h10s').should.equal(3610.0)
    pts('1w2d').should.equal(777600.0)
    pts('1d1w1d').should.equal(777600.0)
  end

  it 'should generate duration strings' do

    tts(0).should.equal('0s')
    tts(0, :drop_seconds => true).should.equal('0m')
    tts(60).should.equal('1m')
    tts(61).should.equal('1m1s')
    tts(3661).should.equal('1h1m1s')
    tts(24 * 3600).should.equal('1d')
    tts(7 * 24 * 3600 + 1).should.equal('1w1s')
    tts(30 * 24 * 3600 + 1).should.equal('4w2d1s')
    tts(30 * 24 * 3600 + 1, :months => true).should.equal('1M1s')
  end

  it 'should compute duration hashes' do

    tdh(0).should.equal({})
    tdh(0.128).should.equal({ :ms => 128 })
    tdh(60.127).should.equal({ :m => 1, :ms => 127 })
    tdh(61.127).should.equal({ :m => 1, :s => 1, :ms => 127 })
    tdh(61.127, :drop_seconds => true).should.equal({ :m => 1 })
  end
end

describe 'rufus/otime#at_to_f' do

  def atf (o)
    Rufus.at_to_f(o)
  end

  it 'should turn Time at values to float' do

    t = Time.now
    tf = t.to_f.to_i.to_f

    atf(t + 2).to_i.to_f.should.equal(tf + 2)
  end

  it 'should turn String at values to float' do

    atf('Sat Mar 21 20:08:01 +0900 2009').should.equal(1237633681.0)
    atf('Sat Mar 21 20:08:01 -0900 2009').should.equal(1237698481.0)
    atf('Sat Mar 21 20:08:01 +0000 2009').should.equal(1237666081.0)
    atf('Sat Mar 21 20:08:01 2009').should.equal(1237666081.0)
    atf('Mar 21 20:08:01 2009').should.equal(1237666081.0)
    atf('2009/03/21 20:08').should.equal(1237666080.0)
  end

  it 'should accept integers' do

    atf(1).should.equal(1.0)
  end
end

