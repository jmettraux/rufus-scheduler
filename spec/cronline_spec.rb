
#
# Specifying rufus-scheduler
#
# Sat Mar 21 12:55:27 JST 2009
#

require File.dirname(__FILE__) + '/spec_base'
require 'tzinfo'

def cl (cronline_string)
  Rufus::CronLine.new(cronline_string)
end


describe Rufus::CronLine do

  def should (line, array)

    cl(line).to_array.should.equal(array)
  end

  it 'should interpret cron strings correctly' do

    should '* * * * *', [ [0], nil, nil, nil, nil, nil, nil ]
    should '10-12 * * * *', [ [0], [10, 11, 12], nil, nil, nil, nil, nil ]
    should '* * * * sun,mon', [ [0], nil, nil, nil, nil, [0, 1], nil ]
    should '* * * * mon-wed', [ [0], nil, nil, nil, nil, [1, 2, 3], nil ]
    should '* * * * 7', [ [0], nil, nil, nil, nil, [0], nil ]
    should '* * * * 0', [ [0], nil, nil, nil, nil, [0], nil ]
    should '* * * * 0,1', [ [0], nil, nil, nil, nil, [0,1], nil ]
    should '* * * * 7,1', [ [0], nil, nil, nil, nil, [0,1], nil ]
    should '* * * * 7,0', [ [0], nil, nil, nil, nil, [0], nil ]
    should '* * * * sun,2-4', [ [0], nil, nil, nil, nil, [0, 2, 3, 4], nil ]

    should '* * * * sun,mon-tue', [ [0], nil, nil, nil, nil, [0, 1, 2], nil ]

    should '* * * * * *', [ nil, nil, nil, nil, nil, nil, nil ]
    should '1 * * * * *', [ [1], nil, nil, nil, nil, nil, nil ]
    should '7 10-12 * * * *', [ [7], [10, 11, 12], nil, nil, nil, nil, nil ]
    should '1-5 * * * * *', [ [1,2,3,4,5], nil, nil, nil, nil, nil, nil ]

    should '* * * * * : EST', [ [0], nil, nil, nil, nil, nil, 'EST' ]
    should '* * * * * : NotATimeZone', [ [0], nil, nil, nil, nil, nil, nil ]
    should '* * * * * * : EST', [ nil, nil, nil, nil, nil, nil, 'EST' ]
    should '* * * * * * : NotATimeZone', [ nil, nil, nil, nil, nil, nil, nil ]
  end
end

describe 'Rufus::CronLine#next_time' do

  it 'should compute next occurence correctly' do

    now = Time.utc(1970,1,1) # Time.at(0).utc # Thu Jan 01 00:00:00 UTC 1970

    cl('* * * * *').next_time(now).should.equal( Time.utc(1970,1,1,0,1) )
    cl('* * * * sun').next_time(now).should.equal( Time.utc(1970,1,4) )
    cl('* * * * * *').next_time(now).should.equal( Time.utc(1970,1,1,0,0,1) )
    cl('* * 13 * fri').next_time(now).should.equal( Time.utc(1970,2,13) )

    cl('10 12 13 12 *').next_time(now).should.equal( Time.utc(1970,12,13,12,10) )
      # this one is slow (1 year == 3 seconds)
    cl('* * 1 6 *').next_time(now).should.equal( Time.utc(1970,6,1) )

    cl('0 0 * * thu').next_time(now).should.equal( Time.utc(1970,1,8) )

    now = Time.local(1970,1,1)

    cl('* * * * *').next_time(now).should.equal( Time.local(1970,1,1,0,1) )
    cl('* * * * sun').next_time(now).should.equal( Time.local(1970,1,4) )
    cl('* * * * * *').next_time(now).should.equal( Time.local(1970,1,1,0,0,1) )
    cl('* * 13 * fri').next_time(now).should.equal( Time.local(1970,2,13) )

    cl('10 12 13 12 *').next_time(now).should.equal( Time.local(1970,12,13,12,10) )
      # this one is slow (1 year == 3 seconds)
    cl('* * 1 6 *').next_time(now).should.equal( Time.local(1970,6,1) )

    cl('0 0 * * thu').next_time(now).should.equal( Time.local(1970,1,8) )
  end

  it 'should compute next occurence correctly with timezones' do
    zone = 'Europe/Stockholm'
    tz = TZInfo::Timezone.get(zone)
    now = tz.local_to_utc(Time.utc(1970,1,1)).utc # Midnight in zone, UTC

    cl("* * * * * : #{zone}").next_time(now).should.equal( Time.utc(1969,12,31,23,1) )
    cl("* * * * sun : #{zone}").next_time(now).should.equal( Time.utc(1970,1,3,23) )
    cl("* * * * * * : #{zone}").next_time(now).should.equal( Time.utc(1969,12,31,23,0,1) )
    cl("* * 13 * fri : #{zone}").next_time(now).should.equal( Time.utc(1970,2,12,23) )

    cl("10 12 13 12 * : #{zone}").next_time(now).should.equal( Time.utc(1970,12,13,11,10) )
      # this one is slow (1 year == 3 seconds)
    cl("* * 1 6 * : #{zone}").next_time(now).should.equal( Time.utc(1970,5,31,23) )

    cl("0 0 * * thu : #{zone}").next_time(now).should.equal( Time.utc(1970,1,7,23) )

    now = tz.local_to_utc(Time.utc(1970,1,1)).localtime # Midnight in zone, local time

    cl("* * * * * : #{zone}").next_time(now).should.equal( Time.local(1969,12,31,18,1) )
    cl("* * * * sun : #{zone}").next_time(now).should.equal( Time.local(1970,1,3,18) )
    cl("* * * * * * : #{zone}").next_time(now).should.equal( Time.local(1969,12,31,18,0,1) )
    cl("* * 13 * fri : #{zone}").next_time(now).should.equal( Time.local(1970,2,12,18) )

    cl("10 12 13 12 * : #{zone}").next_time(now).should.equal( Time.local(1970,12,13,6,10) )
      # this one is slow (1 year == 3 seconds)
    cl("* * 1 6 * : #{zone}").next_time(now).should.equal( Time.local(1970,5,31,19) )

    cl("0 0 * * thu : #{zone}").next_time(now).should.equal( Time.local(1970,1,7,18) )
  end

end

describe "Rufus::Cronline#matches?" do

  it 'should match occurrences' do

    cl('* * * * *').matches?( Time.utc(1970,1,1,0,1) ).should.equal true
    cl('* * * * sun').matches?( Time.utc(1970,1,4) ).should.equal true
    cl('* * * * * *').matches?( Time.utc(1970,1,1,0,0,1) ).should.equal true
    cl('* * 13 * fri').matches?( Time.utc(1970,2,13) ).should.equal true

    cl('10 12 13 12 *').matches?( Time.utc(1970,12,13,12,10) ).should.equal true
    cl('* * 1 6 *').matches?( Time.utc(1970,6,1) ).should.equal true

    cl('0 0 * * thu').matches?( Time.utc(1970,1,8) ).should.equal true

    cl('* * * * *').matches?( Time.local(1970,1,1,0,1) ).should.equal true
    cl('* * * * sun').matches?( Time.local(1970,1,4) ).should.equal true
    cl('* * * * * *').matches?( Time.local(1970,1,1,0,0,1) ).should.equal true
    cl('* * 13 * fri').matches?( Time.local(1970,2,13) ).should.equal true

    cl('10 12 13 12 *').matches?( Time.local(1970,12,13,12,10) ).should.equal true
    cl('* * 1 6 *').matches?( Time.local(1970,6,1) ).should.equal true

    cl('0 0 * * thu').matches?( Time.local(1970,1,8) ).should.equal true
  end

  it 'should match occurrences with timezones' do
    zone = 'Europe/Stockholm'

    cl("* * * * * : #{zone}").matches?( Time.utc(1969,12,31,23,1) ).should.equal true
    cl("* * * * sun : #{zone}").matches?( Time.utc(1970,1,3,23) ).should.equal true
    cl("* * * * * * : #{zone}").matches?( Time.utc(1969,12,31,23,0,1) ).should.equal true
    cl("* * 13 * fri : #{zone}").matches?( Time.utc(1970,2,12,23) ).should.equal true

    cl("10 12 13 12 * : #{zone}").matches?( Time.utc(1970,12,13,11,10) ).should.equal true
    cl("* * 1 6 * : #{zone}").matches?( Time.utc(1970,5,31,23) ).should.equal true

    cl("0 0 * * thu : #{zone}").matches?( Time.utc(1970,1,7,23) ).should.equal true

    cl("* * * * * : #{zone}").matches?( Time.local(1969,12,31,18,1) ).should.equal true
    cl("* * * * sun : #{zone}").matches?( Time.local(1970,1,3,18) ).should.equal true
    cl("* * * * * * : #{zone}").matches?( Time.local(1969,12,31,18,0,1) ).should.equal true
    cl("* * 13 * fri : #{zone}").matches?( Time.local(1970,2,12,18) ).should.equal true

    cl("10 12 13 12 * : #{zone}").matches?( Time.local(1970,12,13,6,10) ).should.equal true
    cl("* * 1 6 * : #{zone}").matches?( Time.local(1970,5,31,19) ).should.equal true

    cl("0 0 * * thu : #{zone}").matches?( Time.local(1970,1,7,18) ).should.equal true
  end

end
