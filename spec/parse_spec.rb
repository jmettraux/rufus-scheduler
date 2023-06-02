
#
# Specifying rufus-scheduler
#
# Wed Apr 17 06:00:59 JST 2013
#

require 'spec_helper'


describe Rufus::Scheduler do

  describe '.parse' do

    def pa(s, opts={}); Rufus::Scheduler.parse(s, opts); end
    def paus(s); Rufus::Scheduler.parse(s).getutc.strftime('%c'); end

    it 'parses duration strings' do

      expect(pa('1.0d1.0w1.0d')).to eq(777600.0)
    end

    it 'parses datetimes' do

      # local

      expect(pa('Sun Nov 18 16:01:00 2012').strftime('%c')).to eq(
        'Sun Nov 18 16:01:00 2012'
      )
    end

    it 'parses datetimes with timezones' do

      expect(
        paus('Sun Nov 18 16:01:00 2012 Asia/Singapore')
      ).to eq('Sun Nov 18 08:01:00 2012')

      expect(
        paus('Sun Nov 18 16:01:00 2012 Zulu')
      ).to eq('Sun Nov 18 16:01:00 2012')

      expect(
        paus('Sun Nov 18 16:01:00 Asia/Singapore 2012')
      ).to eq('Sun Nov 18 08:01:00 2012')

      expect(
        paus('Asia/Singapore Sun Nov 18 16:01:00 2012')
      ).to eq('Sun Nov 18 08:01:00 2012')

      expect(
        paus('Sun Nov 18 16:01:00 2012 America/New_York')
      ).to eq('Sun Nov 18 21:01:00 2012')
    end

    it 'parses datetimes with named timezones' do

      expect(pa(
        'Sun Nov 18 16:01:00 2012 Europe/Berlin'
      ).strftime('%c %z')).to eq(
        'Sun Nov 18 16:01:00 2012 +0100'
      )
    end

    it 'parses datetimes (with the local timezone implicitly)' do

#dump_zones
      #localzone = Time.now.strftime('%z')
      #localzone = 'Z' if localzone == '+0000'
      #expect(
      #  pa('Nov 18 16:01:00 2012').strftime('%c %z')
      #).to eq("Sun Nov 18 16:01:00 2012 #{localzone}")

      expect(pa('Nov 18 16:01:00 2012').strftime('%c')
        ).to eq('Sun Nov 18 16:01:00 2012')
    end

    it 'parses cronlines' do

      out = pa('* * * * *')

      expect(out.class).to eq(Fugit::Cron)
      expect(out.original).to eq('* * * * *')

      expect(pa('10 23 * * *').class).to eq(Fugit::Cron)
      expect(pa('* 23 * * *').class).to eq(Fugit::Cron)
    end

    it 'raises on unparseable input' do

      expect {
        pa('nada')
      }.to raise_error(
        ArgumentError, 'couldn\'t parse "nada" (String)'
      )
    end

    #it 'does not use Chronic if not present' do
    #
    #  without_chronic do
    #
    #    t = pa('next monday 7 PM')
    #    n = Time.now
    #
    #    expect(t.strftime('%Y-%m-%d %H:%M:%S')
    #      ).to eq(n.strftime('%Y-%m-%d') + ' 19:00:00')
    #  end
    #end
      #
      # comment out, grrrr...

    it 'uses Chronic if present' do

      with_chronic do

        t = pa('next monday 7 PM')

        expect(t.wday).to eq(1)
        expect(t.hour).to eq(19)
        expect(t.min).to eq(0)
        expect(t).to be > Time.now
      end
    end

    it 'passes options to Chronic' do

      with_chronic do

        t = pa('monday', :context => :past)

        expect(t.wday).to eq(1)
        expect(t).to be < Time.now
      end
    end

    context 'with Chronic' do

      in_the_future = lambda { |t| t > Time.now }
      tomorrow = Time.now + (24 + 1) * 3600

      {

        'Mon at 2pm' => [
          in_the_future, lambda { |t| t.wday == 1 } ],
        'Wed at 2pm' => [
          in_the_future, lambda { |t| t.wday == 3 } ],
        'Sun at 3pm' => [
          in_the_future, lambda { |t| t.wday == 0 } ],
        'Wed 2pm' => [
          in_the_future, lambda { |t| t.wday == 3 } ],
        'Apr 25 at 2pm' => [
          lambda { |t| t.month == 4 && t.day == 25 && t.hour == 14 } ],
        #'next Apr 25 at 2pm' =>
        #  ArgumentError,
        "next #{tomorrow.strftime('%b %d')} at 2pm" =>
          ArgumentError,

      }.each do |k, outcome|

        title=
          if outcome.is_a?(Class)
            "fails to parse #{k.inspect}"
          else
            "parses #{k.inspect}" +
            (outcome.is_a?(Array) && outcome.include?(in_the_future) ?
              ' in the future' : '')
          end

        it(title) do

          with_chronic do
            r =
              begin
                pa(k)
              rescue => err
                err
              end
            if outcome.is_a?(Class)
              expect(r).to be_a(outcome)
            else
              outcome.each { |l| expect(l[r]).to eq(true) }
            end
          end
        end
      end
    end

    context 'without Chronic' do

      {

        'Mon at 2pm' => lambda { |t| t.wday == 1 },
        'Wed at 2pm' => lambda { |t| t.wday == 3 },
        'Sun at 3pm' => lambda { |t| t.wday == 0 },
        'Wed 2pm' => lambda { |t| t.wday == 3 },
        'Apr 25 at 2pm' => lambda { |t| t.month == 4 && t.day == 25 }

      }.each do |k, v|

        it "parses #{k.inspect} (in the past potentially...)" do

          without_chronic do
            t = pa(k)
            #expect(t > Time.now).to eq(true) # Not necessarily
            expect(v[t]).to eq(true)
          end
        end
      end
    end
  end

  describe '.parse_duration' do

    def pd(s)
      Rufus::Scheduler.parse_duration(s)
    end

    it 'parses duration strings' do

      expect(pd('-1.0d1.0w1.0d')).to eq(-777600.0)
      expect(pd('-1d1w1d')).to eq(-777600.0)
      expect(pd('-1w2d')).to eq(-777600.0)
      expect(pd('-1h10s')).to eq(-3610.0)
      expect(pd('-1h')).to eq(-3600.0)
      expect(pd('-5.s')).to eq(-5.0)
      expect(pd('-2.5s')).to eq(-2.5)
      expect(pd('-1s')).to eq(-1.0)
      expect(pd('-500s')).to eq(-500)
      expect(pd('')).to eq(0.0)
      expect(pd('5.0s')).to eq(5.0)
      expect(pd('0.5s')).to eq(0.5)
      expect(pd('.5s')).to eq(0.5)
      expect(pd('5.s')).to eq(5.0)
      expect(pd('500s')).to eq(500)
      expect(pd('1000s')).to eq(1000)
      expect(pd('1s')).to eq(1.0)
      expect(pd('2.5s')).to eq(2.5)
      expect(pd('1h')).to eq(3600.0)
      expect(pd('1h10s')).to eq(3610.0)
      expect(pd('1w2d')).to eq(777600.0)
      expect(pd('1d1w1d')).to eq(777600.0)
      expect(pd('1.0d1.0w1.0d')).to eq(777600.0)

      expect(pd('.5m')).to eq(30.0)
      expect(pd('5.m')).to eq(300.0)
      expect(pd('1m.5s')).to eq(60.5)
      expect(pd('-.5m')).to eq(-30.0)
    end

    it 'calls #to_s on its input' do

      expect(pd(0.1)).to eq(0.1)
    end

    it 'raises on wrong duration strings' do

      [
        '-', 'h', 'whatever', 'hms', Time.now
      ].each do |x|
        expect { Rufus::Scheduler.parse_duration(x) }.to raise_error(ArgumentError)
      end

      # not since .parse_duration rewrite
      #expect { pd(' 1h ') }.to raise_error(ArgumentError)
    end

    it 'returns nil on unreadable duration when no_error: true' do

      [
        '-', 'h', 'whatever', 'hms', Time.now
      ].each do |x|
        expect(Rufus::Scheduler.parse_duration(x, :no_error => true)).to eq(nil)
      end
    end
  end

  describe '.parse_cron' do

    it 'parses a cron string' do

      c = Rufus::Scheduler.parse_cron('23 0-23/2 * * *')

      expect(c).to be_a(Fugit::Cron)
      expect(c.hours).to eq((0..22).step(2).to_a)
    end

    it 'fails on non cron string' do

      expect {
        Rufus::Scheduler.parse_cron('nada 23 0-23/2 * * *')
      }.to raise_error(
        ArgumentError, 'invalid cron string "nada 23 0-23/2 * * *"'
      )
    end

    it 'returns nil on cron string when no_error: true' do

      expect(
        Rufus::Scheduler.parse_cron('nada 23 0-23/2 * * *', no_error: true)
      ).to eq(nil)
    end
  end

  describe '.to_duration' do

    def td(o, opts={})
      Rufus::Scheduler.to_duration(o, opts)
    end

    it 'turns integers into duration strings' do

      expect(td(0)).to eq('0s')
      expect(td(60)).to eq('1m')
      expect(td(61)).to eq('1m1s')
      expect(td(3661)).to eq('1h1m1s')
      expect(td(24 * 3600)).to eq('1d')
      expect(td(7 * 24 * 3600 + 1)).to eq('1w1s')
      expect(td(30 * 24 * 3600 + 1)).to eq('4w2d1s')
    end

    it 'ignores seconds and milliseconds if :drop_seconds => true' do

      expect(td(0, :drop_seconds => true)).to eq('0m')
      expect(td(5, :drop_seconds => true)).to eq('0m')
      expect(td(61, :drop_seconds => true)).to eq('1m')
    end

    it 'displays months if :months => true' do

      expect(td(1, :months => true)).to eq('1s')
      expect(td(30 * 24 * 3600 + 1, :months => true)).to eq('1M1s')
    end

    it 'turns floats into duration strings' do

      expect(td(0.1)).to eq('0.1s')
      expect(td(1.1)).to eq('1.1s')
    end
  end

  describe '.to_duration_hash' do

    [

      [ 0, nil, { :s => 0 } ],
      [ 60, nil, { :m => 1 } ],
      [ 0.128, nil, { :s => 0.128 } ],
      [ 60.127, nil, { :m => 1, :s => 0.127 } ],
      [ 61.127, nil, { :m => 1, :s => 1.127 } ],
      [ 61.127, { :drop_seconds => true }, { :m => 1 } ],

    ].each do |f, o, h| # float, options, hash

      it "turns #{f.inspect} into #{h.inspect} #{o ? "(#{o.inspect})" : ''}" do

        expect(Rufus::Scheduler.to_duration_hash(f, o || {})).to eq(h)
      end
    end
  end
end

