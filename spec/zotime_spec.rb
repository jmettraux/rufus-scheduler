# encoding: UTF-8

#
# Specifying rufus-scheduler
#
# Wed Mar 11 21:17:36 JST 2015, quatre ans...
#

require 'spec_helper'


describe Rufus::Scheduler::ZoTime do

  describe '.get_tzone' do

    def gtz(s); z = Rufus::Scheduler::ZoTime.get_tzone(s); z ? z.name : z; end

    it 'returns a tzone for all the know zone strings' do

      expect(gtz('GB')).to eq('GB')
      expect(gtz('UTC')).to eq('UTC')
      expect(gtz('GMT')).to eq('GMT')
      expect(gtz('Zulu')).to eq('Zulu')
      expect(gtz('Japan')).to eq('Japan')
      expect(gtz('Turkey')).to eq('Turkey')
      expect(gtz('Asia/Tokyo')).to eq('Asia/Tokyo')
      expect(gtz('Europe/Paris')).to eq('Europe/Paris')
      expect(gtz('Europe/Zurich')).to eq('Europe/Zurich')
      expect(gtz('W-SU')).to eq('W-SU')

      expect(gtz('PST')).to eq('America/Dawson')
      expect(gtz('CEST')).to eq('Africa/Ceuta')

      expect(gtz('Z')).to eq('Zulu')

      expect(gtz('+09:00')).to eq('+09:00')
      expect(gtz('-01:30')).to eq('-01:30')

      expect(gtz('+08:00')).to eq('+08:00')
      expect(gtz('+0800')).to eq('+0800') # no normalization to "+08:00"

      expect(gtz(3600)).to eq('+01:00')
    end

    it 'returns nil for unknown zone names' do

      expect(gtz('Asia/Paris')).to eq(nil)
      expect(gtz('Nada/Nada')).to eq(nil)
      expect(gtz('7')).to eq(nil)
      expect(gtz('06')).to eq(nil)
      expect(gtz('sun#3')).to eq(nil)
      expect(gtz('Mazda Zoom Zoom Stadium')).to eq(nil)
    end

    # gh-222
    it "falls back to ENV['TZ'] if it doesn't know Time.now.zone" do

      begin

        current = Rufus::Scheduler::ZoTime.get_tzone(:current)

        class ::Time
          alias _original_zone zone
          def zone; "中国标准时间"; end
        end

        expect(
          Rufus::Scheduler::ZoTime.get_tzone(:current)
        ).to eq(nil)

        expect(
          Rufus::Scheduler::ZoTime.get_tzone(:current)
        ).to eq(
          Rufus::Scheduler::ZoTime.get_tzone(Time.now.zone)
        )

        in_zone 'Asia/Shanghai' do

          expect(
            Rufus::Scheduler::ZoTime.get_tzone(:current)
          ).to eq(
            Rufus::Scheduler::ZoTime.get_tzone('Asia/Shanghai')
          )
        end

      ensure

        class ::Time
          def zone; _original_zone; end
        end
      end

      expect(
        Rufus::Scheduler::ZoTime.get_tzone(:current)
      ).to eq(
        current
      )
    end

    [ # for gh-228

      [ 'Asia/Tokyo', 'Asia/Tokyo' ],
      [ 'Asia/Shanghai', 'Asia/Shanghai' ],
      [ 'Europe/Zurich', 'Europe/Zurich' ],
      [ 'Europe/London', 'Europe/London' ]

    ].each do |zone, target|

      it "returns the current timezone for :current in #{zone}" do

        in_zone(zone) do

          expect(
            Rufus::Scheduler::ZoTime.get_tzone(:current)
          ).to eq(
            Rufus::Scheduler::ZoTime.get_tzone(target)
          )
        end
      end
    end


#    it 'flips burgers' do
#      p Rufus::Scheduler::CronLine.new('* * * * *').to_a
#      p Rufus::Scheduler::ZoTime.get_tzone(:current)
#      in_zone 'Asia/Shanghai' do
#        p ENV['TZ']
#        p Rufus::Scheduler::CronLine.new('* * * * *').to_a
#        p Rufus::Scheduler::ZoTime.get_tzone(:current)
#      end
#      ENV['TZ'] = 'Asia/Shanghai'
#      p Rufus::Scheduler::CronLine.new('* * * * *').to_a
#      #p Rufus::Scheduler::ZoTime.get_tzone('Asia/Shanghai')
#      #p Rufus::Scheduler::ZoTime.get_tzone('America/Bahia_Banderas')
#      #p Rufus::Scheduler::ZoTime.get_tzone('Asia/Shanghai').now
#      #p Rufus::Scheduler::ZoTime.get_tzone('America/Bahia_Banderas').now
#      p Rufus::Scheduler::ZoTime.get_tzone(:current)
#    end
  end

  describe '.new' do

    it 'accepts an integer' do

      zt = Rufus::Scheduler::ZoTime.new(1234567890, 'America/Los_Angeles')

      expect(zt.seconds.to_i).to eq(1234567890)
    end

    it 'accepts a float' do

      zt = Rufus::Scheduler::ZoTime.new(1234567890.1234, 'America/Los_Angeles')

      expect(zt.seconds.to_i).to eq(1234567890)
    end

    it 'accepts a Time instance' do

      zt =
        Rufus::Scheduler::ZoTime.new(
          Time.utc(2007, 11, 1, 15, 25, 0),
          'America/Los_Angeles')

      expect(zt.seconds.to_i).to eq(1193930700)
    end
  end

  describe '.parse' do

    it 'parses a time string without a timezone' do

      zt =
        in_zone('Europe/Moscow') {
          Rufus::Scheduler::ZoTime.parse('2015/03/08 01:59:59')
        }

      t = zt
      u = zt.utc

      expect(t.to_i).to eq(1425769199)
      expect(u.to_i).to eq(1425769199)

      expect(t.strftime('%Y/%m/%d %H:%M:%S %Z %z') + " #{t.isdst}"
        ).to eq('2015/03/08 01:59:59 MSK +0300 false')

      expect(u.to_debug_s).to eq('t 2015-03-07 22:59:59 +00:00 dst:false')
    end

    it 'parses a time string with a full name timezone' do

      zt =
        Rufus::Scheduler::ZoTime.parse(
          '2015/03/08 01:59:59 America/Los_Angeles')

      t = zt
      u = zt.utc

      expect(t.to_i).to eq(1425808799)
      expect(u.to_i).to eq(1425808799)

      expect(t.to_debug_s).to eq('zt 2015-03-08 01:59:59 -08:00 dst:false')
      expect(u.to_debug_s).to eq('t 2015-03-08 09:59:59 +00:00 dst:false')
    end

    it 'parses a time string with a delta timezone' do

      zt =
        in_zone('Europe/Berlin') {
          Rufus::Scheduler::ZoTime.parse('2015-12-13 12:30 -0200')
        }

      t = zt
      u = zt.utc

      expect(t.to_i).to eq(1450017000)
      expect(u.to_i).to eq(1450017000)

      expect(t.to_debug_s).to eq('zt 2015-12-13 12:30:00 -02:00 dst:false')
      expect(u.to_debug_s).to eq('t 2015-12-13 14:30:00 +00:00 dst:false')
    end

    it 'parses a time string with a delta (:) timezone' do

      zt =
        in_zone('Europe/Berlin') {
          Rufus::Scheduler::ZoTime.parse('2015-12-13 12:30 -02:00')
        }

      t = zt
      u = zt.utc

      expect(t.to_i).to eq(1450017000)
      expect(u.to_i).to eq(1450017000)

      expect(t.to_debug_s).to eq('zt 2015-12-13 12:30:00 -02:00 dst:false')
      expect(u.to_debug_s).to eq('t 2015-12-13 14:30:00 +00:00 dst:false')
    end

    it 'takes the local TZ when it does not know the timezone' do

      in_zone 'Europe/Moscow' do

        zt = Rufus::Scheduler::ZoTime.parse('2015/03/08 01:59:59 Nada/Nada')

        expect(zt.zone.name).to eq('Europe/Moscow')
      end
    end

    it 'fails on invalid strings' do

      expect {
        Rufus::Scheduler::ZoTime.parse('xxx')
      }.to raise_error(
        ArgumentError, 'no time information in "xxx"'
      )
    end
  end

  describe '.make' do

    it 'accepts a Time' do

      expect(
        Rufus::Scheduler::ZoTime.make(
          Time.utc(2016, 11, 01, 12, 30, 9)).to_debug_s
      ).to eq(
        'zt 2016-11-01 12:30:09 +00:00 dst:false'
      )
    end

    it 'accepts a Date' do

      expect(
        Rufus::Scheduler::ZoTime.make(
          Date.new(2016, 11, 01))
      ).to eq(
        Rufus::Scheduler::ZoTime.new(
          Time.local(2016, 11, 01).to_f, nil)
      )
    end

    it 'accepts a String' do

      expect(
        Rufus::Scheduler::ZoTime.make(
          '2016-11-01 12:30:09')
      ).to eq(
        Rufus::Scheduler::ZoTime.new(
          Time.local(2016, 11, 01, 12, 30, 9).to_f, nil)
      )
    end

    it 'accepts a String (Zulu)' do

      expect(
        Rufus::Scheduler::ZoTime.make(
          '2016-11-01 12:30:09Z')
      ).to eq(
        Rufus::Scheduler::ZoTime.new(
          Time.utc(2016, 11, 01, 12, 30, 9).to_f, 'Zulu')
      )
    end

    it 'accepts a String (ss+01:00)' do

      expect(
        Rufus::Scheduler::ZoTime.make('2016-11-01 12:30:09+01:00').to_debug_s
      ).to eq(
        'zt 2016-11-01 12:30:09 +01:00 dst:false'
      )
    end

    it 'accepts a String (ss-01)' do

      expect(
        Rufus::Scheduler::ZoTime.make('2016-11-01 12:30:09-01').to_debug_s
      ).to eq(
        'zt 2016-11-01 12:30:09 -01:00 dst:false'
      )
    end

    it 'accepts a duration String' do

      expect(
        Rufus::Scheduler::ZoTime.make('1h')
      ).to be_between(
        Time.now + 3600 - 1, Time.now + 3600 + 1
      )
    end

    it 'accepts a Numeric' do

      expect(
        Rufus::Scheduler::ZoTime.make(3600)
      ).to be_between(
        Time.now + 3600 - 1, Time.now + 3600 + 1
      )
    end

    it 'rejects unparseable input' do

      expect {
        Rufus::Scheduler::ZoTime.make('xxx')
      #}.to raise_error(ArgumentError, 'couldn\'t parse "xxx"')
      }.to raise_error(ArgumentError, 'no time information in "xxx"')
        # straight out of Time.parse()

      expect {
        Rufus::Scheduler::ZoTime.make(Object.new)
      }.to raise_error(ArgumentError, /\Acannot turn /)
    end
  end

  describe '#to_time' do

    it 'returns a local Time instance, although with a UTC zone' do

      zt = Rufus::Scheduler::ZoTime.new(1193898300, 'America/Los_Angeles')
      t = zt.to_time

      expect(zt.to_debug_s).to eq('zt 2007-10-31 23:25:00 -08:00 dst:true')

      expect(t.to_i).to eq(1193898300 - 7 * 3600) # /!\

      expect(t.to_debug_s).to eq('t 2007-10-31 23:25:00 +00:00 dst:false')
        # Time instance stuck to UTC...
    end
  end

  describe '#utc' do

    it 'returns an UTC Time instance' do

      zt = Rufus::Scheduler::ZoTime.new(1193898300, 'America/Los_Angeles')
      ut = zt.utc

      expect(ut.to_i).to eq(1193898300)

      expect(zt.to_debug_s).to eq('zt 2007-10-31 23:25:00 -08:00 dst:true')
      expect(ut.to_debug_s).to eq('t 2007-11-01 06:25:00 +00:00 dst:false')
    end
  end

  describe '#add' do

    it 'adds seconds' do

      zt = Rufus::Scheduler::ZoTime.new(1193898300, 'Europe/Paris')
      zt.add(111)

      expect(zt.seconds).to eq(1193898300 + 111)
    end

    it 'goes into DST' do

      zt =
        Rufus::Scheduler::ZoTime.new(
          Time.gm(2015, 3, 8, 9, 59, 59),
          'America/Los_Angeles')

      t0 = zt.dup
      zt.add(1)
      t1 = zt

      st0 = t0.strftime('%Y/%m/%d %H:%M:%S %Z') + " #{t0.isdst}"
      st1 = t1.strftime('%Y/%m/%d %H:%M:%S %Z') + " #{t1.isdst}"

      expect(t0.to_i).to eq(1425808799)
      expect(t1.to_i).to eq(1425808800)
      expect(st0).to eq('2015/03/08 01:59:59 PST false')
      expect(st1).to eq('2015/03/08 03:00:00 PDT true')
    end

    it 'goes out of DST' do

      zt =
        Rufus::Scheduler::ZoTime.new(
          ltz('Europe/Berlin', 2014, 10, 26, 01, 59, 59),
          'Europe/Berlin')

      t0 = zt.dup
      zt.add(1)
      t1 = zt.dup
      zt.add(3600)
      t2 = zt.dup
      zt.add(1)
      t3 = zt

      st0 = t0.strftime('%Y/%m/%d %H:%M:%S %Z') + " #{t0.isdst}"
      st1 = t1.strftime('%Y/%m/%d %H:%M:%S %Z') + " #{t1.isdst}"
      st2 = t2.strftime('%Y/%m/%d %H:%M:%S %Z') + " #{t2.isdst}"
      st3 = t3.strftime('%Y/%m/%d %H:%M:%S %Z') + " #{t3.isdst}"

      expect(t0.to_i).to eq(1414281599)
      expect(t1.to_i).to eq(1414285200 - 3600)
      expect(t2.to_i).to eq(1414285200)
      expect(t3.to_i).to eq(1414285201)

      expect(st0).to eq('2014/10/26 01:59:59 CEST true')
      expect(st1).to eq('2014/10/26 02:00:00 CEST true')
      expect(st2).to eq('2014/10/26 02:00:00 CET false')
      expect(st3).to eq('2014/10/26 02:00:01 CET false')

      expect(t1 - t0).to eq(1)
      expect(t2 - t1).to eq(3600)
      expect(t3 - t2).to eq(1)
    end
  end

  describe '#to_f' do

    it 'returns the @seconds' do

      zt = Rufus::Scheduler::ZoTime.new(1193898300, 'Europe/Paris')

      expect(zt.to_f).to eq(1193898300)
    end
  end

  describe '#strftime' do

    it 'accepts %Z, %z, %:z and %::z' do

      expect(
        Rufus::Scheduler::ZoTime.new(0, 'Europe/Bratislava') \
          .strftime('%Y-%m-%d %H:%M:%S %Z %z %:z %::z')
      ).to eq(
        '1970-01-01 01:00:00 CET +0100 +01:00 +01:00:00'
      )
    end

    it 'accepts %/Z' do

      expect(
        Rufus::Scheduler::ZoTime.new(0, 'Europe/Bratislava') \
          .strftime('%Y-%m-%d %H:%M:%S %/Z')
      ).to eq(
        "1970-01-01 01:00:00 Europe/Bratislava"
      )
    end
  end

  describe '#monthdays' do

    def mds(t); Rufus::Scheduler::ZoTime.new(t.to_f, nil).monthdays; end

    it 'returns the appropriate "0#2"-like string' do

      expect(mds(local(1970, 1, 1))).to eq(%w[ 4#1 4#-5 ])
      expect(mds(local(1970, 1, 7))).to eq(%w[ 3#1 3#-4 ])
      expect(mds(local(1970, 1, 14))).to eq(%w[ 3#2 3#-3 ])

      expect(mds(local(2011, 3, 11))).to eq(%w[ 5#2 5#-3 ])
    end
  end

  describe '.extract_iso8601_zone' do

    def eiz(s); Rufus::Scheduler::ZoTime.extract_iso8601_zone(s); end

    it 'returns the zone string' do

      expect(eiz '2016-11-01 12:30:09-01').to eq('-01:00')
      expect(eiz '2016-11-01 12:30:09-01:00').to eq('-01:00')
      expect(eiz '2016-11-01 12:30:09 -01').to eq('-01:00')
      expect(eiz '2016-11-01 12:30:09 -01:00').to eq('-01:00')

      expect(eiz '2016-11-01 12:30:09-01:30').to eq('-01:30')
      expect(eiz '2016-11-01 12:30:09 -01:30').to eq('-01:30')
    end

    it 'returns nil when it cannot find a zone' do

      expect(eiz '2016-11-01 12:30:09').to eq(nil)
      expect(eiz '2016-11-01 12:30:09-25').to eq(nil)
      expect(eiz '2016-11-01 12:30:09-25:00').to eq(nil)
    end
  end
end

