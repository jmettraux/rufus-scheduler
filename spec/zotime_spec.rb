
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
          Time.new(2007, 11, 1, 15, 25, 0, "+09:00"),
          'America/Los_Angeles')

      expect(zt.seconds.to_i).to eq(1193898300)
    end

    context 'when TZInfo present' do

      it 'uses TZInfo to resolve time zones'
    end
  end

  describe '#time' do

    it 'returns a Time instance in with the right offset' do

      zt = Rufus::Scheduler::ZoTime.new(1193898300, 'America/Los_Angeles')
      t = zt.time

      expect(t.strftime('%Y/%m/%d %H:%M:%S %Z')
        ).to eq('2007/10/31 23:25:00 PDT')
    end
  end

  describe '#utc' do

    it 'returns an UTC Time instance' do

      zt = Rufus::Scheduler::ZoTime.new(1193898300, 'America/Los_Angeles')
      t = zt.utc

      expect(t.strftime('%Y/%m/%d %H:%M:%S %Z %s')
        ).to eq('2007/11/01 06:25:00 UTC 1193898300')
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

      expect(st0).to eq('2015/03/08 01:59:59 PST 1425808799 false')
      expect(st1).to eq('2015/03/08 03:00:00 PDT 1425808800 true')
    end

    it 'goes out of DST' do

      zt =
        Rufus::Scheduler::ZoTime.new(
          Time.gm(2014, 10, 26, 00, 59, 59),
          'Europe/Berlin')

      t0 = zt.time
      zt.add(1)
      t1 = zt.time

      st0 = t0.strftime('%Y/%m/%d %H:%M:%S %Z %s') + " #{t0.isdst}"
      st1 = t1.strftime('%Y/%m/%d %H:%M:%S %Z %s') + " #{t1.isdst}"

      expect(st0).to eq('2014/10/26 02:59:59 CEST 1414285199 true')
      expect(st1).to eq('2014/10/26 02:00:00 CET 1414285200 false')
    end
  end

  describe '#to_f' do

    it 'returns the @seconds' do

      zt = Rufus::Scheduler::ZoTime.new(1193898300, 'Europe/Paris')

      expect(zt.to_f).to eq(1193898300)
    end
  end

  describe '.is_timezone?' do

    it 'returns true when passed a string describing a timezone'

    context 'when TZInfo present' do

      it 'returns true when passed a string describing a timezone'
    end
  end

  describe '.parse' do

    it 'parses a time string' do

      zt =
        Rufus::Scheduler::ZoTime.parse(
          '2015/03/08 01:59:59 America/Los_Angeles')
      t = zt.time

      expect(t.strftime('%Y/%m/%d %H:%M:%S %Z %s') + " #{t.isdst}"
        ).to eq('2015/03/08 01:59:59 PST 1425808799 false')
    end

    it 'returns nil when it cannot parse' do

      zt = Rufus::Scheduler::ZoTime.parse('2015/03/08 01:59:59 Nada/Nada')

      expect(zt).to eq(nil)
    end

    context 'when TZInfo present' do

      it 'parses a time string'
      it 'returns nil when it cannot parse'
    end
  end
end

