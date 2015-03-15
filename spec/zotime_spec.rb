
#
# Specifying rufus-scheduler
#
# Wed Mar 11 21:17:36 JST 2015, quatre ans...
#

require 'spec_helper'


describe Rufus::Scheduler::ZoTime do

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
          Time.local(2007, 11, 1, 15, 25, 0, "+09:00"),
          'America/Los_Angeles')

      expect(zt.seconds.to_i).to eq(1193898300)
    end
  end

  #it "flips burgers" do
  #  puts "---"
  #  t0 = ltz('America/New_York', 2004, 10, 31, 0, 30, 0)
  #  t1 = ltz('America/New_York', 2004, 10, 31, 1, 30, 0)
  #  p t0
  #  p t1
  #  puts "---"
  #  zt0 = Rufus::Scheduler::ZoTime.new(t0, 'America/New_York')
  #  zt1 = Rufus::Scheduler::ZoTime.new(t1, 'America/New_York')
  #  p zt0.time
  #  p zt1.time
  #  puts "---"
  #  zt0.add(3600)
  #  p [ zt0.time, zt0.time.zone ]
  #  p [ zt1.time, zt1.time.zone ]
  #  #puts "---"
  #  #zt0.add(3600)
  #  #zt1.add(3600)
  #  #p [ zt0.time, zt0.time.zone ]
  #  #p [ zt1.time, zt1.time.zone ]
  #end

  describe '#time' do

    it 'returns a Time instance in with the right offset' do

      zt = Rufus::Scheduler::ZoTime.new(1193898300, 'America/Los_Angeles')
      t = zt.time

      expect(t.strftime('%Y/%m/%d %H:%M:%S %Z')
        ).to eq('2007/10/31 23:25:00 PDT')
    end

    # New York      EST: UTC-5
    # summer (dst)  EDT: UTC-4

    it 'chooses the non DST time when there is ambiguity' do

      t = ltz('America/New_York', 2004, 10, 31, 0, 30, 0)
      zt = Rufus::Scheduler::ZoTime.new(t, 'America/New_York')
      zt.add(3600)
      ztt = zt.time

      if ruby18?
        expect(ztt.strftime('%Y/%m/%d %H:%M:%S %Z %s')
          ).to eq('2004/10/31 01:30:00 EST 1099153800')
      else
        expect(ztt.strftime('%Y/%m/%d %H:%M:%S %Z %s')
          ).to eq('2004/10/31 01:30:00 EST 1099204200')
      end
    end
  end

  describe '#utc' do

    it 'returns an UTC Time instance' do

      zt = Rufus::Scheduler::ZoTime.new(1193898300, 'America/Los_Angeles')
      t = zt.utc

      if ruby18?
        expect(t.strftime('%Y/%m/%d %H:%M:%S %Z %s')
          ).to eq('2007/11/01 06:25:00 GMT 1193865900')
      else
        expect(t.strftime('%Y/%m/%d %H:%M:%S %Z %s')
          ).to eq('2007/11/01 06:25:00 UTC 1193898300')
      end
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

      t0 = zt.time
      zt.add(1)
      t1 = zt.time

      st0 = t0.strftime('%Y/%m/%d %H:%M:%S %Z %s') + " #{t0.isdst}"
      st1 = t1.strftime('%Y/%m/%d %H:%M:%S %Z %s') + " #{t1.isdst}"

      if ruby18?
        expect(st0).to eq('2015/03/08 01:59:59 PST 1425747599 false')
        expect(st1).to eq('2015/03/08 03:00:00 PDT 1425751200 true')
      else
        expect(st0).to eq('2015/03/08 01:59:59 PST 1425808799 false')
        expect(st1).to eq('2015/03/08 03:00:00 PDT 1425808800 true')
      end
    end

    it 'goes out of DST' do

      zt =
        Rufus::Scheduler::ZoTime.new(
          ltz('Europe/Berlin', 2014, 10, 26, 01, 59, 59),
          'Europe/Berlin')

      t0 = zt.time
      zt.add(1)
      t1 = zt.time
      zt.add(3600)
      t2 = zt.time
      zt.add(1)
      t3 = zt.time

      st0 = t0.strftime('%Y/%m/%d %H:%M:%S %Z %s') + " #{t0.isdst}"
      st1 = t1.strftime('%Y/%m/%d %H:%M:%S %Z %s') + " #{t1.isdst}"
      st2 = t2.strftime('%Y/%m/%d %H:%M:%S %Z %s') + " #{t2.isdst}"
      st3 = t3.strftime('%Y/%m/%d %H:%M:%S %Z %s') + " #{t3.isdst}"

      if ruby18?
        expect(st0).to eq('2014/10/26 01:59:59 CEST 1414256399 true')
        expect(st1).to eq('2014/10/26 02:00:00 CET 1414256400 false')
        expect(st2).to eq('2014/10/26 02:00:00 CET 1414256400 false')
        expect(st3).to eq('2014/10/26 02:00:01 CET 1414256401 false')
      else
        expect(st0).to eq('2014/10/26 01:59:59 CEST 1414281599 true')
        expect(st1).to eq('2014/10/26 02:00:00 CET 1414285200 false')
        expect(st2).to eq('2014/10/26 02:00:00 CET 1414285200 false')
        expect(st3).to eq('2014/10/26 02:00:01 CET 1414285201 false')
      end

      expect(t1 - t0).to eq(3601)
      expect(t2 - t1).to eq(0)
      expect(t3 - t2).to eq(1)
    end
  end

  describe '#to_f' do

    it 'returns the @seconds' do

      zt = Rufus::Scheduler::ZoTime.new(1193898300, 'Europe/Paris')

      expect(zt.to_f).to eq(1193898300)
    end
  end

  describe '.is_timezone?' do

    def is_timezone?(o); Rufus::Scheduler::ZoTime.is_timezone?(o); end

    it 'returns true when passed a string describing a timezone' do

      expect(is_timezone?('Asia/Tokyo')).to eq(true)
      expect(is_timezone?('Europe/Paris')).to eq(true)
      expect(is_timezone?('UTC')).to eq(true)
      expect(is_timezone?('GMT')).to eq(true)
      expect(is_timezone?('Z')).to eq(true)
      expect(is_timezone?('Zulu')).to eq(true)
      expect(is_timezone?('PST')).to eq(true)
      expect(is_timezone?('+09:00')).to eq(true)
      expect(is_timezone?('-01:30')).to eq(true)
    end

    it 'returns false when it cannot make sense of the timezone' do

      expect(is_timezone?('Asia/Paris')).to eq(false)
      expect(is_timezone?('YTC')).to eq(false)
      expect(is_timezone?('Nada/Nada')).to eq(false)
    end
  end

  describe '.looks_like_a_timezone?' do

    def llat?(o); Rufus::Scheduler::ZoTime.looks_like_a_timezone?(o); end

    it 'may return true' do

      expect(llat?('Asia/Tokyo')).to eq(true)
      expect(llat?('America/Los_Angeles')).to eq(true)
      expect(llat?('Europe/Paris')).to eq(true)
      expect(llat?('UTC')).to eq(true)
      expect(llat?('PST')).to eq(true)

      expect(llat?('Asia/Paris')).to eq(true)
      expect(llat?('YTC')).to eq(true)
      expect(llat?('Nada/Nada')).to eq(true)

      expect(llat?('Z')).to eq(true)
    end

    it 'may return false' do

      expect(llat?('14:00')).to eq(false)
      expect(llat?('14:00:14')).to eq(false)
      expect(llat?('2014/12/11')).to eq(false)
      expect(llat?('2014-12-11')).to eq(false)
      expect(llat?('Wed')).to eq(false)
      expect(llat?('+25:00')).to eq(false)

      expect(llat?('+09:00')).to eq(false)
      expect(llat?('-01:30')).to eq(false)
    end
  end

  describe '.parse' do

    it 'parses a time string without a timezone' do

      zt =
        in_zone('Europe/Moscow') {
          Rufus::Scheduler::ZoTime.parse('2015/03/08 01:59:59')
        }

      t = zt.time
      u = zt.utc

      if ruby18?
        expect(t.strftime('%Y/%m/%d %H:%M:%S %Z %s') + " #{t.isdst}"
          ).to eq('2015/03/08 01:59:59 MSK 1425747599 false')
        expect(u.strftime('%Y/%m/%d %H:%M:%S %Z %s') + " #{u.isdst}"
          ).to eq('2015/03/07 22:59:59 GMT 1425736799 false')
      else
        expect(t.strftime('%Y/%m/%d %H:%M:%S %Z %s') + " #{t.isdst}"
          ).to eq('2015/03/08 01:59:59 MSK 1425769199 false')
        expect(u.strftime('%Y/%m/%d %H:%M:%S %Z %s') + " #{u.isdst}"
          ).to eq('2015/03/07 22:59:59 UTC 1425769199 false')
      end
    end

    it 'parses a time string with a full name timezone' do

      zt =
        Rufus::Scheduler::ZoTime.parse(
          '2015/03/08 01:59:59 America/Los_Angeles')

      t = zt.time
      u = zt.utc

      if ruby18?
        expect(t.strftime('%Y/%m/%d %H:%M:%S %Z %s') + " #{t.isdst}"
          ).to eq('2015/03/08 01:59:59 PST 1425747599 false')
        expect(u.strftime('%Y/%m/%d %H:%M:%S %Z %s') + " #{u.isdst}"
          ).to eq('2015/03/08 09:59:59 GMT 1425776399 false')
      else
        expect(t.strftime('%Y/%m/%d %H:%M:%S %Z %s') + " #{t.isdst}"
          ).to eq('2015/03/08 01:59:59 PST 1425808799 false')
        expect(u.strftime('%Y/%m/%d %H:%M:%S %Z %s') + " #{u.isdst}"
          ).to eq('2015/03/08 09:59:59 UTC 1425808799 false')
      end
    end

    it 'parses a time string with a delta timezone' do

      zt =
        in_zone('Europe/Berlin') {
          Rufus::Scheduler::ZoTime.parse('2015-12-13 12:30 -0200')
        }

      t = zt.time
      u = zt.utc

      if ruby18?
        expect(t.strftime('%Y/%m/%d %H:%M:%S %Z %s') + " #{t.isdst}"
          ).to eq('2015/12/13 15:30:00 CET 1449988200 false')
        expect(u.strftime('%Y/%m/%d %H:%M:%S %Z %s') + " #{u.isdst}"
          ).to eq('2015/12/13 14:30:00 GMT 1449984600 false')
      else
        expect(t.strftime('%Y/%m/%d %H:%M:%S %Z %s') + " #{t.isdst}"
          ).to eq('2015/12/13 15:30:00 CET 1450017000 false')
        expect(u.strftime('%Y/%m/%d %H:%M:%S %Z %s') + " #{u.isdst}"
          ).to eq('2015/12/13 14:30:00 UTC 1450017000 false')
      end
    end

    it 'parses a time string with a delta (:) timezone' do

      zt =
        in_zone('Europe/Berlin') {
          Rufus::Scheduler::ZoTime.parse('2015-12-13 12:30 -02:00')
        }

      t = zt.time
      u = zt.utc

      if ruby18?
        expect(t.strftime('%Y/%m/%d %H:%M:%S %Z %s') + " #{t.isdst}"
          ).to eq('2015/12/13 15:30:00 CET 1449988200 false')
        expect(u.strftime('%Y/%m/%d %H:%M:%S %Z %s') + " #{u.isdst}"
          ).to eq('2015/12/13 14:30:00 GMT 1449984600 false')
      else
        expect(t.strftime('%Y/%m/%d %H:%M:%S %Z %s') + " #{t.isdst}"
          ).to eq('2015/12/13 15:30:00 CET 1450017000 false')
        expect(u.strftime('%Y/%m/%d %H:%M:%S %Z %s') + " #{u.isdst}"
          ).to eq('2015/12/13 14:30:00 UTC 1450017000 false')
      end
    end

    it 'returns nil when it cannot parse' do

      zt = Rufus::Scheduler::ZoTime.parse('2015/03/08 01:59:59 Nada/Nada')

      expect(zt).to eq(nil)
    end
  end
end

