
#
# Specifying rufus-scheduler
#
# Sat Mar 21 12:55:27 JST 2009
#

require File.join(File.dirname(__FILE__), 'spec_base')


describe Rufus::CronLine do

  def cl(cronline_string)
    Rufus::CronLine.new(cronline_string)
  end
  def should(line, array)
    cl(line).to_array.should == array
  end

  describe '.new' do

    it 'interprets cron strings correctly' do

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
    end

    it 'interprets cron strings with TZ correctly' do

      should '* * * * * EST', [ [0], nil, nil, nil, nil, nil, 'EST' ]
      should '* * * * * * EST', [ nil, nil, nil, nil, nil, nil, 'EST' ]

      lambda { cl '* * * * * NotATimeZone' }.should raise_error
      lambda { cl '* * * * * * NotATimeZone' }.should raise_error
    end
  end

  describe '#next_time' do

    def nt(cronline, now)
      Rufus::CronLine.new(cronline).next_time(now)
    end

    it 'computes the next occurence correctly' do

      now = Time.at(0).utc # Thu Jan 01 00:00:00 UTC 1970

      nt('* * * * *', now).should == now + 60
      nt('* * * * sun', now).should == now + 259200
      nt('* * * * * *', now).should == now + 1
      nt('* * 13 * fri', now).should == now + 3715200

      nt('10 12 13 12 *', now).should == now + 29938200
        # this one is slow (1 year == 3 seconds)

      nt('0 0 * * thu', now).should == now + 604800

      now = Time.local(2008, 12, 31, 23, 59, 59, 0)

      nt('* * * * *', now).should == now + 1
    end

#
# the specs that follow are from Tanzeeb Khalili
#

    it 'computes the next occurence correctly (TZ not specified)' do

      now = Time.utc(1970, 1, 1) # Time.at(0).utc # Thu Jan 01 00:00:00 UTC 1970

      nt('* * * * *', now).should == Time.utc(1970, 1, 1, 0, 1)
      nt('* * * * sun', now).should == Time.utc(1970, 1, 4)
      nt('* * * * * *', now).should == Time.utc(1970, 1, 1, 0, 0, 1)
      nt('* * 13 * fri', now).should == Time.utc(1970, 2, 13)

      nt('10 12 13 12 *', now).should == Time.utc(1970, 12, 13, 12, 10)
        # this one is slow (1 year == 3 seconds)
      nt('* * 1 6 *', now).should == Time.utc(1970, 6, 1)

      nt('0 0 * * thu', now).should == Time.utc(1970, 1, 8)

      now = Time.local(1970, 1, 1)

      nt('* * * * *', now).should == Time.local(1970, 1, 1, 0, 1)
      nt('* * * * sun', now).should == Time.local(1970, 1, 4)
      nt('* * * * * *', now).should == Time.local(1970, 1, 1, 0, 0, 1)
      nt('* * 13 * fri', now).should == Time.local(1970, 2, 13)

      nt('10 12 13 12 *', now).should == Time.local(1970, 12, 13, 12, 10)
        # this one is slow (1 year == 3 seconds)
      nt('* * 1 6 *', now).should == Time.local(1970, 6, 1)

      nt('0 0 * * thu', now).should == Time.local(1970, 1, 8)
    end

    it 'computes the next occurence correctly (TZ specified)' do

      zone = 'Europe/Stockholm'
      tz = TZInfo::Timezone.get(zone)
      now = tz.local_to_utc(Time.utc(1970, 1, 1)).utc
        # Midnight in zone, UTC

      nt("* * * * * #{zone}", now).should == Time.utc(1969, 12, 31, 23, 1)
      nt("* * * * sun #{zone}", now).should == Time.utc(1970, 1, 3, 23)
      nt("* * * * * * #{zone}", now).should == Time.utc(1969, 12, 31, 23, 0, 1)
      nt("* * 13 * fri #{zone}", now).should == Time.utc(1970, 2, 12, 23)

      nt("10 12 13 12 * #{zone}", now).should == Time.utc(1970, 12, 13, 11, 10)
        # this one is slow (1 year == 3 seconds)
      nt("* * 1 6 * #{zone}", now).should == Time.utc(1970, 5, 31, 23)

      nt("0 0 * * thu #{zone}", now).should == Time.utc(1970, 1, 7, 23)

      now = tz.local_to_utc(Time.utc(1970, 1, 1)).localtime
        # Midnight in zone, local time

      nt("* * * * * #{zone}", now).should == Time.local(1969, 12, 31, 18, 1)
      nt("* * * * sun #{zone}", now).should == Time.local(1970, 1, 3, 18)
      nt("* * * * * * #{zone}", now).should == Time.local(1969, 12, 31, 18, 0, 1)
      nt("* * 13 * fri #{zone}", now).should == Time.local(1970, 2, 12, 18)

      nt("10 12 13 12 * #{zone}", now).should == Time.local(1970, 12, 13, 6, 10)
        # this one is slow (1 year == 3 seconds)
      nt("* * 1 6 * #{zone}", now).should == Time.local(1970, 5, 31, 19)

      nt("0 0 * * thu #{zone}", now).should == Time.local(1970, 1, 7, 18)
    end
  end

  describe '#matches?' do

    it 'matches correctly (TZ not specified)' do

      cl('* * * * *').matches?(Time.utc(1970, 1, 1, 0, 1)).should == true
      cl('* * * * sun').matches?(Time.utc(1970, 1, 4)).should == true
      cl('* * * * * *').matches?(Time.utc(1970, 1, 1, 0, 0, 1)).should == true
      cl('* * 13 * fri').matches?(Time.utc(1970, 2, 13)).should == true

      cl('10 12 13 12 *').matches?(Time.utc(1970, 12, 13, 12, 10)).should == true
      cl('* * 1 6 *').matches?(Time.utc(1970, 6, 1)).should == true

      cl('0 0 * * thu').matches?(Time.utc(1970, 1, 8)).should == true

      cl('* * * * *').matches?(Time.local(1970, 1, 1, 0, 1)).should == true
      cl('* * * * sun').matches?(Time.local(1970, 1, 4)).should == true
      cl('* * * * * *').matches?(Time.local(1970, 1, 1, 0, 0, 1)).should == true
      cl('* * 13 * fri').matches?(Time.local(1970, 2, 13)).should == true

      cl('10 12 13 12 *').matches?(Time.local(1970, 12, 13, 12, 10)).should == true
      cl('* * 1 6 *').matches?(Time.local(1970, 6, 1)).should == true

      cl('0 0 * * thu').matches?(Time.local(1970, 1, 8)).should == true
    end

    it 'matches correctly (TZ specified)' do

      zone = 'Europe/Stockholm'

      cl("* * * * * #{zone}").matches?(Time.utc(1969, 12, 31, 23, 1)).should == true
      cl("* * * * sun #{zone}").matches?(Time.utc(1970, 1, 3, 23)).should == true
      cl("* * * * * * #{zone}").matches?(Time.utc(1969, 12, 31, 23, 0, 1)).should == true
      cl("* * 13 * fri #{zone}").matches?(Time.utc(1970, 2, 12, 23)).should == true

      cl("10 12 13 12 * #{zone}").matches?(Time.utc(1970, 12, 13, 11, 10)).should == true
      cl("* * 1 6 * #{zone}").matches?(Time.utc(1970, 5, 31, 23)).should == true

      cl("0 0 * * thu #{zone}").matches?(Time.utc(1970, 1, 7, 23)).should == true

      cl("* * * * * #{zone}").matches?(Time.local(1969, 12, 31, 18, 1)).should == true
      cl("* * * * sun #{zone}").matches?(Time.local(1970, 1, 3, 18)).should == true
      cl("* * * * * * #{zone}").matches?(Time.local(1969, 12, 31, 18, 0, 1)).should == true
      cl("* * 13 * fri #{zone}").matches?(Time.local(1970, 2, 12, 18)).should == true

      cl("10 12 13 12 * #{zone}").matches?(Time.local(1970, 12, 13, 6, 10)).should == true
      cl("* * 1 6 * #{zone}").matches?(Time.local(1970, 5, 31, 19)).should == true

      cl("0 0 * * thu #{zone}").matches?(Time.local(1970, 1, 7, 18)).should == true
    end
  end
end

