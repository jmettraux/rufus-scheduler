
#
# Specifying rufus-scheduler
#
# Sat Mar 21 12:55:27 JST 2009
#

require File.dirname(__FILE__) + '/spec_base'


def cl(cronline_string)
  Rufus::CronLine.new(cronline_string)
end


describe Rufus::CronLine do

  def should(line, array)

    cl(line).to_array.should.equal(array)
  end

  it 'should interpret cron strings correctly' do

    should '* * * * *', [ [0], nil, nil, nil, nil, nil ]
    should '10-12 * * * *', [ [0], [10, 11, 12], nil, nil, nil, nil ]
    should '* * * * sun,mon', [ [0], nil, nil, nil, nil, [0, 1] ]
    should '* * * * mon-wed', [ [0], nil, nil, nil, nil, [1, 2, 3] ]
    should '* * * * 7', [ [0], nil, nil, nil, nil, [0] ]
    should '* * * * 0', [ [0], nil, nil, nil, nil, [0] ]
    should '* * * * 0,1', [ [0], nil, nil, nil, nil, [0,1] ]
    should '* * * * 7,1', [ [0], nil, nil, nil, nil, [0,1] ]
    should '* * * * 7,0', [ [0], nil, nil, nil, nil, [0] ]
    should '* * * * sun,2-4', [ [0], nil, nil, nil, nil, [0, 2, 3, 4] ]

    should '* * * * sun,mon-tue', [ [0], nil, nil, nil, nil, [0, 1, 2] ]

    should '* * * * * *', [ nil, nil, nil, nil, nil, nil ]
    should '1 * * * * *', [ [1], nil, nil, nil, nil, nil ]
    should '7 10-12 * * * *', [ [7], [10, 11, 12], nil, nil, nil, nil ]
    should '1-5 * * * * *', [ [1,2,3,4,5], nil, nil, nil, nil, nil ]
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

end

