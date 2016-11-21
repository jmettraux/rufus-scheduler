
#
# Specifying rufus-scheduler
#
# Sun Jun  1 05:52:24 JST 2014
#

require 'spec_helper'


describe 'basics' do

  def tts(time)

    #time.strftime('%Y-%m-%d %H:%M:%S %z') + (time.dst? ? ' dst' : '')
    [
      time.strftime('%Y-%m-%d %H:%M:%S'),
      time.utc_offset.to_s,
      time.dst? ? 'dst' : ''
    ].select { |s| s.length > 0 }.join(' ')
  end

  describe 'Time.new' do

    it 'accepts a timezone final argument' do

      if jruby? or ruby18?

        expect(true).to be(true)

      else

        expect(
          tts(Time.new(2014, 1, 1, 1, 0, 0, '+01:00'))
        ).to eq('2014-01-01 01:00:00 3600')
        expect(
          tts(Time.new(2014, 8, 1, 1, 0, 0, '+01:00'))
        ).to eq('2014-08-01 01:00:00 3600')
        expect(
          tts(Time.new(2014, 8, 1, 1, 0, 0, '+01:00'))
        ).to eq('2014-08-01 01:00:00 3600')
      end
    end
  end

  describe 'Time.local' do

    it 'works as expected' do

      expect(
        tts(in_zone('Europe/Berlin') { Time.local(2014, 1, 1, 1, 0, 0) })
      ).to eq('2014-01-01 01:00:00 3600')
      expect(
        tts(in_zone('Europe/Berlin') { Time.local(2014, 8, 1, 1, 0, 0) })
      ).to eq('2014-08-01 01:00:00 7200 dst')
    end
  end
end

