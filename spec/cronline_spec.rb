
#
# Specifying rufus-scheduler
#
# Sat Mar 21 12:55:27 JST 2009
#

require File.dirname(__FILE__) + '/spec_base'


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

    now = Time.at(0).utc # Thu Jan 01 00:00:00 UTC 1970

    cl('* * * * *').next_time(now).should.equal(now + 60)
    cl('* * * * sun').next_time(now).should.equal(now + 259200)
    cl('* * * * * *').next_time(now).should.equal(now + 1)
    cl('* * 13 * fri').next_time(now).should.equal(now + 3715200)

    cl('10 12 13 12 *').next_time(now).should.equal(now + 29938200)
      # this one is slow (1 year == 3 seconds)

    cl('0 0 * * thu').next_time(now).should.equal(now + 604800)

    now = Time.local(2008, 12, 31, 23, 59, 59, 0)

    cl('* * * * *').next_time(now).should.equal(now + 1)
  end
=begin
  it 'should compute next occurence correctly with timezones' do
    zone = 'Stockholm'
    offset = Time.at(0).utc.utc_offset - Time.at(0).in_time_zone(zone).utc_offset
    now = Time.at(0).utc # Thu Jan 01 00:00:00 UTC 1970

    cl('* * * * * : Stockholm').next_time(now).should.equal(now + 60 + offset)
    cl('* * * * sun : Stockholm').next_time(now).should.equal(now + 259200 + offset)
    cl('* * * * * * : Stockholm').next_time(now).should.equal(now + 1 + offset)
    cl('* * 13 * fri : Stockholm').next_time(now).should.equal(now + 3715200 + offset)

    cl('10 12 13 12 * : Stockholm').next_time(now).should.equal(now + 29938200 + offset)
      # this one is slow (1 year == 3 seconds)

    cl('0 0 * * thu : Stockholm').next_time(now).should.equal(now + 604800 + offset)

    now = Time.local(2008, 12, 31, 23, 59, 59, 0)

    cl('* * * * * : Stockholm').next_time(now).should.equal(now + 1)
  end
=end
end

