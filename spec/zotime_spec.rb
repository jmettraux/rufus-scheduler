
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

      expect(t.strftime('%Y/%m/%d %H:%M:%S %Z')
        ).to eq('2007/11/01 06:25:00 UTC')
    end
  end

  describe '#add' do

    it 'adds seconds' do

      zt = Rufus::Scheduler::ZoTime.new(1193898300, 'Europe/Paris')
      zt.add(111)

      expect(zt.seconds).to eq(1193898300 + 111)
    end
  end

  describe '#to_f' do

    it 'returns the @seconds' do

      zt = Rufus::Scheduler::ZoTime.new(1193898300, 'Europe/Paris')

      expect(zt.to_f).to eq(1193898300)
    end
  end
end

