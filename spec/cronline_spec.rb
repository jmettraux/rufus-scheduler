
#
# Specifying rufus-scheduler
#
# Sat Mar 21 12:55:27 JST 2009
#

require 'spec_helper'


describe Rufus::Scheduler::CronLine do

  def cl(cronline_string)
    Rufus::Scheduler::CronLine.new(cronline_string)
  end

  def nt(cronline, now)
    Rufus::Scheduler::CronLine.new(cronline).next_time(now)
  end
  def ntz(cronline, now)
    tz = cronline.split.last
    tu = nt(cronline, now).utc
    in_zone(tz) { tu.getlocal }
  end

  def pt(cronline, now)
    Rufus::Scheduler::CronLine.new(cronline).previous_time(now)
  end
  def ptz(cronline, now)
    tz = cronline.split.last
    tu = pt(cronline, now).utc
    in_zone(tz) { tu.getlocal }
  end

  def ns(cronline, now)
    Rufus::Scheduler::CronLine.new(cronline).next_second(now)
  end

  def match(line, time)
    expect(cl(line).matches?(time)).to eq(true)
  end
  def no_match(line, time)
    expect(cl(line).matches?(time)).to eq(false)
  end
  def to_a(line, array)
    expect(cl(line).to_array).to eq(array)
  end

  describe '.new' do

    it 'interprets cron strings correctly' do

      to_a '* * * * *', [ [0], nil, nil, nil, nil, nil, nil, nil ]
      to_a '10-12 * * * *', [ [0], [10, 11, 12], nil, nil,  nil, nil, nil, nil ]
      to_a '* * * * sun,mon', [ [0], nil, nil, nil, nil, [0, 1], nil, nil ]
      to_a '* * * * mon-wed', [ [0], nil, nil, nil, nil, [1, 2, 3], nil, nil ]
      to_a '* * * * 7', [ [0], nil, nil, nil, nil, [0], nil, nil ]
      to_a '* * * * 0', [ [0], nil, nil, nil, nil, [0], nil, nil ]
      to_a '* * * * 0,1', [ [0], nil, nil, nil, nil, [0,1], nil, nil ]
      to_a '* * * * 7,1', [ [0], nil, nil, nil, nil, [0,1], nil, nil ]
      to_a '* * * * 7,0', [ [0], nil, nil, nil, nil, [0], nil, nil ]
      to_a '* * * * sun,2-4', [ [0], nil, nil, nil, nil, [0, 2, 3, 4], nil, nil ]

      to_a '* * * * sun,mon-tue', [ [0], nil, nil, nil, nil, [0, 1, 2], nil, nil ]

      to_a '* * * * * *', [ nil, nil, nil, nil, nil, nil, nil, nil ]
      to_a '1 * * * * *', [ [1], nil, nil, nil, nil, nil, nil, nil ]
      to_a '7 10-12 * * * *', [ [7], [10, 11, 12], nil, nil, nil, nil, nil, nil ]
      to_a '1-5 * * * * *', [ [1,2,3,4,5], nil, nil, nil, nil, nil, nil, nil ]

      to_a '0 0 1 1 *', [ [0], [0], [0], [1], [1], nil, nil, nil ]

      to_a '52 0 * * *', [ [0], [52], [0], nil, nil, nil, nil, nil ]

      #if ruby18?
      #  to_a '0 23-24 * * *', [ [0], [0], [0, 23], nil, nil, nil, nil, nil ]
      #else
      #  to_a '0 23-24 * * *', [ [0], [0], [23, 0], nil, nil, nil, nil, nil ]
      #end
        #
        # as reported by Aimee Rose in
        # https://github.com/jmettraux/rufus-scheduler/issues/56
      to_a '0 23-24 * * *', [ [0], [0], [0, 23], nil, nil, nil, nil, nil ]

      #if ruby18?
      #  to_a '0 23-2 * * *', [ [0], [0], [0, 1, 2, 23], nil, nil, nil, nil, nil ]
      #else
      #  to_a '0 23-2 * * *', [ [0], [0], [23, 0, 1, 2], nil, nil, nil, nil, nil ]
      #end
      to_a '0 23-2 * * *', [ [0], [0], [0, 1, 2, 23], nil, nil, nil, nil, nil ]

      # modulo forms work for five-field forms
      to_a '*/17 * * * *', [[0], [0, 17, 34, 51], nil, nil, nil, nil, nil, nil]
      to_a '13 */17 * * *', [[0], [13], [0, 17], nil, nil, nil, nil, nil]

      # modulo forms work for six-field forms
      to_a '*/17 * * * * *', [[0, 17, 34, 51], nil, nil, nil, nil, nil, nil, nil]
      to_a '13 */17 * * * *', [[13], [0, 17, 34, 51], nil, nil, nil, nil, nil, nil]
    end

    it 'rejects invalid weekday expressions' do

      expect { cl '0 17 * * MON_FRI' }.to raise_error(ArgumentError)
        # underline instead of dash

      expect { cl '* * * * 9' }.to raise_error(ArgumentError)
      expect { cl '* * * * 0-12' }.to raise_error(ArgumentError)
      expect { cl '* * * * BLABLA' }.to raise_error(ArgumentError)
    end

    it 'rejects invalid cronlines' do

      expect { cl '* nada * * 9' }.to raise_error(ArgumentError)
    end

    it 'interprets cron strings with TZ correctly' do

      to_a('* * * * * EST', [ [0], nil, nil, nil, nil, nil, nil, 'EST' ])
      to_a('* * * * * * EST', [ nil, nil, nil, nil, nil, nil, nil, 'EST' ])

      to_a(
        '* * * * * * America/Chicago',
        [ nil, nil, nil, nil, nil, nil, nil, 'America/Chicago' ])
      to_a(
        '* * * * * * America/New_York',
        [ nil, nil, nil, nil, nil, nil, nil, 'America/New_York' ])

      expect { cl '* * * * * NotATimeZone' }.to raise_error(ArgumentError)
      expect { cl '* * * * * * NotATimeZone' }.to raise_error(ArgumentError)
    end

    it 'interprets cron strings with / (slashes) correctly' do

      to_a(
        '0 */2 * * *',
        [ [0], [0], (0..23).select { |e| e.even? }, nil, nil, nil, nil, nil ])
      to_a(
        '0 0-23/2 * * *',
        [ [0], [0], (0..23).select { |e| e.even? }, nil, nil, nil, nil, nil ])
      to_a(
        '0 7-23/2 * * *',
        [ [0], [0], (7..23).select { |e| e.odd? }, nil, nil, nil, nil, nil ])
      to_a(
        '*/10 * * * *',
        [ [0], [0, 10, 20, 30, 40, 50], nil, nil, nil, nil, nil, nil ])

      # fighting https://github.com/jmettraux/rufus-scheduler/issues/65
      #
      to_a(
        '*/10 * * * * Europe/Berlin',
        [ [0], [ 0, 10, 20, 30, 40, 50], nil, nil, nil, nil, nil, 'Europe/Berlin' ])
    end

    it 'accepts lonely / (slashes) (like <= 2.0.19 did)' do

      # fighting https://github.com/jmettraux/rufus-scheduler/issues/65

      to_a(
        '/10 * * * *',
        [ [0], [ 0, 10, 20, 30, 40, 50], nil, nil, nil, nil, nil, nil ])
    end

    it 'rejects / for days (every other wednesday)' do

      expect {
        Rufus::Scheduler::CronLine.new('* * * * wed/2')
      }.to raise_error(ArgumentError)
    end

    it 'does not support ranges for monthdays (sun#1-sun#2)' do

      expect {
        Rufus::Scheduler::CronLine.new('* * * * sun#1-sun#2')
      }.to raise_error(ArgumentError)
    end

    it 'accepts items with initial 0' do

      to_a(
        '09 * * * *', [ [0], [9], nil, nil, nil, nil, nil, nil ])
      to_a(
        '09-12 * * * *', [ [0], [9, 10, 11, 12], nil, nil, nil, nil, nil, nil ])
      to_a(
        '07-08 * * * *', [ [0], [7, 8], nil, nil, nil, nil, nil, nil ])
      to_a(
        '* */08 * * *', [ [0], nil, [0, 8, 16], nil, nil, nil, nil, nil ])
      to_a(
        '* */07 * * *', [ [0], nil, [0, 7, 14, 21], nil, nil, nil, nil, nil ])
      to_a(
        '* 01-09/04 * * *', [ [0], nil, [1, 5, 9], nil, nil, nil, nil, nil ])
      to_a(
        '* * * * 06', [ [0], nil, nil, nil, nil, [6], nil, nil ])
    end

    it 'interprets cron strings with L correctly' do

      to_a(
        '* * L * *', [[0], nil, nil, ['L'], nil, nil, nil, nil ])
      to_a(
        '* * 2-5,L * *', [[0], nil, nil, [2,3,4,5,'L'], nil, nil, nil, nil ])
      to_a(
        '* * */8,L * *', [[0], nil, nil, [1,9,17,25,'L'], nil, nil, nil, nil ])
    end

    it 'does not support ranges for L' do

      expect { cl '* * 15-L * *'}.to raise_error(ArgumentError)
      expect { cl '* * L/4 * *'}.to raise_error(ArgumentError)
    end

    it 'does not support multiple Ls' do

      expect { cl '* * L,L * *'}.to raise_error(ArgumentError)
    end

    it 'raises if L is used for something else than days' do

      expect { cl '* L * * *'}.to raise_error(ArgumentError)
    end

    it 'raises for out of range input' do

      expect { cl '60-62 * * * *'}.to raise_error(ArgumentError)
      expect { cl '62 * * * *'}.to raise_error(ArgumentError)
      expect { cl '60 * * * *'}.to raise_error(ArgumentError)
      expect { cl '* 25-26 * * *'}.to raise_error(ArgumentError)
      expect { cl '* 25 * * *'}.to raise_error(ArgumentError)
        #
        # as reported by Aimee Rose in
        # https://github.com/jmettraux/rufus-scheduler/pull/58
    end

    it 'sorts seconds' do

      to_a(
        '23,30,10 * * * * *', [ [10,23,30], nil, nil, nil, nil, nil, nil, nil ])
    end

    it 'sorts minutes' do

      to_a(
        '23,30,10 * * * * ', [ [0], [10,23,30], nil, nil, nil, nil, nil, nil ])
    end

    it 'sorts days' do

      to_a(
        '* * 14,7 * * ', [ [0], nil, nil, [7, 14], nil, nil, nil, nil ])
    end

    it 'sorts months' do

      to_a(
        '* * * 11,3,4 * ', [ [0], nil, nil, nil, [3,4,11], nil, nil, nil ])
    end

    it 'sorts days of week' do

      to_a(
        '* * * * Sun,Fri,2 ', [ [0], nil, nil, nil, nil, [0, 2, 5], nil, nil ])
    end
  end

  describe '#next_time' do

    it 'computes the next occurence correctly' do

      in_zone 'Europe/Berlin' do

        now = Time.at(0) - 3600

        expect(nt('* * * * *', now)).to eq(now + 60)
        expect(nt('* * * * sun', now)).to eq(now + 259200)
        expect(nt('* * * * * *', now)).to eq(now + 1)
        expect(nt('* * 13 * fri', now)).to eq(now + 3715200)

        expect(nt('10 12 13 12 *', now)).to eq(now + 29938200)
          # this one is slow (1 year == 3 seconds)
          #
          # historical note:
          # (comment made in 2006 or 2007, the underlying libs got better and
          # that slowness is gone)

        expect(nt('0 0 * * thu', now)).to eq(now + 604800)
        expect(nt('00 0 * * thu', now)).to eq(now + 604800)

        expect(nt('0 0 * * *', now)).to eq(now + 24 * 3600)
        expect(nt('0 24 * * *', now)).to eq(now + 24 * 3600)

        now = local(2008, 12, 31, 23, 59, 59, 0)

        expect(nt('* * * * *', now)).to eq(now + 1)
      end
    end

    it 'computes the next occurence correctly in local TZ (TZ not specified)' do

      now = local(1970, 1, 1)

      expect(nt('* * * * *', now)).to eq(local(1970, 1, 1, 0, 1))
      expect(nt('* * * * sun', now)).to eq(local(1970, 1, 4))
      expect(nt('* * * * * *', now)).to eq(local(1970, 1, 1, 0, 0, 1))
      expect(nt('* * 13 * fri', now)).to eq(local(1970, 2, 13))

      expect(nt('10 12 13 12 *', now)).to eq(local(1970, 12, 13, 12, 10))
        # this one is slow (1 year == 3 seconds)
      expect(nt('* * 1 6 *', now)).to eq(local(1970, 6, 1))

      expect(nt('0 0 * * thu', now)).to eq(local(1970, 1, 8))
    end

    it 'computes the next occurence correctly in UTC (TZ specified)' do

      zone = 'Europe/Stockholm'
      now = in_zone(zone) { Time.local(1970, 1, 1) }

      expect(nt("* * * * * #{zone}", now)).to eq(utc(1969, 12, 31, 23, 1))
      expect(nt("* * * * sun #{zone}", now)).to eq(utc(1970, 1, 3, 23))
      expect(nt("* * * * * * #{zone}", now)).to eq(utc(1969, 12, 31, 23, 0, 1))
      expect(nt("* * 13 * fri #{zone}", now)).to eq(utc(1970, 2, 12, 23))

      expect(nt("10 12 13 12 * #{zone}", now)).to eq(utc(1970, 12, 13, 11, 10))
      expect(nt("* * 1 6 * #{zone}", now)).to eq(utc(1970, 5, 31, 23))

      expect(nt("0 0 * * thu #{zone}", now)).to eq(utc(1970, 1, 7, 23))
    end

    it 'computes the next time correctly when there is a sun#2 involved' do

      expect(nt('* * * * sun#1', local(1970, 1, 1))).to eq(local(1970, 1, 4))
      expect(nt('* * * * sun#2', local(1970, 1, 1))).to eq(local(1970, 1, 11))

      expect(nt('* * * * sun#2', local(1970, 1, 12))).to eq(local(1970, 2, 8))
    end

    it 'computes next time correctly when there is a sun#2,sun#3 involved' do

      expect(
        nt('* * * * sun#2,sun#3', local(1970, 1, 1))).to eq(local(1970, 1, 11))
      expect(
        nt('* * * * sun#2,sun#3', local(1970, 1, 12))).to eq(local(1970, 1, 18))
    end

    it 'understands sun#L' do

      expect(nt('* * * * sun#L', local(1970, 1, 1))).to eq(local(1970, 1, 25))
    end

    it 'understands sun#-1' do

      expect(nt('* * * * sun#-1', local(1970, 1, 1))).to eq(local(1970, 1, 25))
    end

    it 'understands sun#-2' do

      expect(nt('* * * * sun#-2', local(1970, 1, 1))).to eq(local(1970, 1, 18))
    end

    it 'computes the next time correctly when "L" (last day of month)' do

      expect(nt('* * L * *', lo(1970, 1, 1))).to eq(lo(1970, 1, 31))
      expect(nt('* * L * *', lo(1970, 2, 1))).to eq(lo(1970, 2, 28))
      expect(nt('* * L * *', lo(1972, 2, 1))).to eq(lo(1972, 2, 29))
      expect(nt('* * L * *', lo(1970, 4, 1))).to eq(lo(1970, 4, 30))
    end

    it 'returns a time with subseconds chopped off' do

      expect(
        nt('* * * * *', Time.now).usec).to eq(0)
      expect(
        nt('* * * * *', Time.now).iso8601(10).match(/\.0+[^\d]/)).not_to eq(nil)
    end

    # New York      EST: UTC-5
    # summer (dst)  EDT: UTC-4

    # gh-127
    #
    it 'survives TZInfo::AmbiguousTime' do

      if ruby18? or jruby?
        expect(
          ntz(
            '30 1 31 10 * America/New_York',
            ltz('America/New_York', 2004, 10, 1)
          ).strftime('%Y-%m-%d %H:%M:%S')
        ).to eq('2004-10-31 01:30:00')
      else
        expect(
          ntz(
            '30 1 31 10 * America/New_York',
            ltz('America/New_York', 2004, 10, 1)
          )
        ).to eq(ltz('America/New_York', 2004, 10, 31, 1, 30, 0))
      end
    end

    # gh-127
    #
    it 'survives TZInfo::PeriodNotFound' do

      expect(
        ntz(
          '0 2 9 3 * America/New_York',
          ltz('America/New_York', 2014, 3, 1)
        )
      ).to eq(ltz('America/New_York', 2015, 3, 9, 2, 0, 0))
    end

    it 'understands six-field crontabs' do

      expect(nt('* * * * * *',local(1970,1,1,1,1,1))).to(
        eq(local(1970,1,1,1,1,2))
      )
      expect(nt('* * * * * *',local(1970,1,1,1,1,2))).to(
        eq(local(1970,1,1,1,1,3))
      )
      expect(nt('*/10 * * * * *',local(1970,1,1,1,1,0))).to(
        eq(local(1970,1,1,1,1,10))
      )
      expect(nt('*/10 * * * * *',local(1970,1,1,1,1,9))).to(
        eq(local(1970,1,1,1,1,10))
      )
      expect(nt('*/10 * * * * *',local(1970,1,1,1,1,10))).to(
        eq(local(1970,1,1,1,1,20))
      )
      expect(nt('*/10 * * * * *',local(1970,1,1,1,1,40))).to(
        eq(local(1970,1,1,1,1,50))
      )
      expect(nt('*/10 * * * * *',local(1970,1,1,1,1,49))).to(
        eq(local(1970,1,1,1,1,50))
      )
      expect(nt('*/10 * * * * *',local(1970,1,1,1,1,50))).to(
        eq(local(1970,1,1,1,2,00))
      )
    end
  end

  describe '#next_second' do
    [
      [ '*/10 * * * * *', local(1970,1,1,1,1, 0),  0 ], # 0 sec to  0s mark
      [ '*/10 * * * * *', local(1970,1,1,1,1, 1),  9 ], # 9 sec to 10s mark
      [ '*/10 * * * * *', local(1970,1,1,1,1, 9),  1 ], # 1 sec to 10s mark
      [ '*/10 * * * * *', local(1970,1,1,1,1,10),  0 ], # 0 sec to 10s mark
      [ '*/10 * * * * *', local(1970,1,1,1,1,11),  9 ], # 9 sec to 20s mark
      [ '*/10 * * * * *', local(1970,1,1,1,1,19),  1 ], # 1 sec to 20s mark
      [ '*/10 * * * * *', local(1970,1,1,1,1,20),  0 ], # 0 sec to 20s mark
      [ '*/10 * * * * *', local(1970,1,1,1,1,21),  9 ], # 1 sec to 30s mark
      # ...
      [ '*/10 * * * * *', local(1970,1,1,1,1,49),  1 ], # 9 sec to 50s mark
      [ '*/10 * * * * *', local(1970,1,1,1,1,50),  0 ], # 0 sec to 50s mark
      [ '*/10 * * * * *', local(1970,1,1,1,1,51),  9 ],
    ].each do |cronline, now, sec|
      it "ensures that next_second('#{cronline}', #{now}) is #{sec}" do
        expect(ns(cronline,now)).to eq(sec)
      end
    end
  end

  describe '#previous_time' do

    it 'returns the previous time the cron should have triggered' do

      expect(
        pt('* * * * sun', lo(1970, 1, 1))).to eq(lo(1969, 12, 28, 23, 59, 00))
      expect(
        pt('* * 13 * *', lo(1970, 1, 1))).to eq(lo(1969, 12, 13, 23, 59, 00))
      expect(
        pt('0 12 13 * *', lo(1970, 1, 1))).to eq(lo(1969, 12, 13, 12, 00))
      expect(
        pt('0 0 2 1 *', lo(1970, 1, 1))).to eq(lo(1969, 1, 2, 0, 00))

      expect(
        pt('* * * * * sun', lo(1970, 1, 1))).to eq(lo(1969, 12, 28, 23, 59, 59))
    end

    # New York      EST: UTC-5
    # summer (dst)  EDT: UTC-4

    # gh-127
    #
    it 'survives TZInfo::AmbiguousTime' do

      if ruby18? or jruby?
        expect(
          ptz(
            '30 1 31 10 * America/New_York',
            ltz('America/New_York', 2004, 10, 31, 14, 30, 0)
          ).strftime('%Y-%m-%d %H:%M:%S')
        ).to eq('2004-10-31 01:30:00')
      else
        expect(
          ptz(
            '30 1 31 10 * America/New_York',
            ltz('America/New_York', 2004, 10, 31, 14, 30, 0)
          )
        ).to eq(ltz('America/New_York', 2004, 10, 31, 1, 30, 0))
      end
    end

    # gh-127
    #
    it 'survives TZInfo::PeriodNotFound' do

      expect(
        ptz(
          '0 2 9 3 * America/New_York',
          ltz('America/New_York', 2015, 3, 9, 12, 0, 0)
        )
      ).to eq(ltz('America/New_York', 2015, 3, 9, 2, 0, 0))
    end

    it 'computes correctly when * 0,10,20' do

      expect(
        pt('* 0,10,20 * * *', lo(2000, 1, 1))).to eq(
          lo(1999, 12, 31, 20, 59, 00))
    end

    it 'computes correctly when * */10' do

      expect(
        pt('* */10 * * *', lo(2000, 1, 1))).to eq(
          lo(1999, 12, 31, 20, 59, 00))
    end
  end

  describe '#matches?' do

#    it 'matches correctly in UTC (TZ not specified)' do
#
#      match '* * * * *', utc(1970, 1, 1, 0, 1)
#      match '* * * * sun', utc(1970, 1, 4)
#      match '* * * * * *', utc(1970, 1, 1, 0, 0, 1)
#      match '* * 13 * fri', utc(1970, 2, 13)
#
#      match '10 12 13 12 *', utc(1970, 12, 13, 12, 10)
#      match '* * 1 6 *', utc(1970, 6, 1)
#
#      match '0 0 * * thu', utc(1970, 1, 8)
#
#      match '0 0 1 1 *', utc(2012, 1, 1)
#      no_match '0 0 1 1 *', utc(2012, 1, 1, 1, 0)
#    end

    it 'matches correctly in local TZ (TZ not specified)' do

      match '* * * * *', local(1970, 1, 1, 0, 1)
      match '* * * * sun', local(1970, 1, 4)
      match '* * * * * *', local(1970, 1, 1, 0, 0, 1)
      match '* * 13 * fri', local(1970, 2, 13)

      match '10 12 13 12 *', local(1970, 12, 13, 12, 10)
      match '* * 1 6 *', local(1970, 6, 1)

      match '0 0 * * thu', local(1970, 1, 8)

      match '0 0 1 1 *', local(2012, 1, 1)
      no_match '0 0 1 1 *', local(2012, 1, 1, 1, 0)
    end

    it 'matches correctly in UTC (TZ specified)' do

      zone = 'Europe/Stockholm'

      match "* * * * * #{zone}", utc(1969, 12, 31, 23, 1)
      match "* * * * sun #{zone}", utc(1970, 1, 3, 23)
      match "* * * * * * #{zone}", utc(1969, 12, 31, 23, 0, 1)
      match "* * 13 * fri #{zone}", utc(1970, 2, 12, 23)

      match "10 12 13 12 * #{zone}", utc(1970, 12, 13, 11, 10)
      match "* * 1 6 * #{zone}", utc(1970, 5, 31, 23)

      match "0 0 * * thu #{zone}", utc(1970, 1, 7, 23)
    end

    it 'matches correctly when there is a sun#2 involved' do

      match '* * 13 * fri#2', utc(1970, 2, 13)
      no_match '* * 13 * fri#2', utc(1970, 2, 20)
    end

    it 'matches correctly when there is a L involved' do

      match '* * L * *', utc(1970, 1, 31)
      no_match '* * L * *', utc(1970, 1, 30)
    end

    it 'matches correctly when there is a sun#2,sun#3 involved' do

      no_match '* * * * sun#2,sun#3', local(1970, 1, 4)
      match '* * * * sun#2,sun#3', local(1970, 1, 11)
      match '* * * * sun#2,sun#3', local(1970, 1, 18)
      no_match '* * * * sun#2,sun#3', local(1970, 1, 25)
    end

    it 'matches correctly for seconds' do

      match '* * * * * *', local(1970, 1, 11)
      match '* * * * * *', local(1970, 1, 11, 0, 0, 13)
    end

    it 'matches correctly for seconds / interval' do

      match '*/2 * * * * *', local(1970, 1, 11)
      match '*/5 * * * * *', local(1970, 1, 11)
      match '*/5 * * * * *', local(1970, 1, 11, 0, 0, 0)
      no_match '*/5 * * * * *', local(1970, 1, 11, 0, 0, 1)
      match '*/5 * * * * *', local(1970, 1, 11, 0, 0, 5)
      match '*/2 * * * * *', local(1970, 1, 11, 0, 0, 2)
      match '*/2 * * * * *', local(1970, 1, 11, 0, 0, 2, 500)
    end
  end

  describe '#monthdays' do

    it 'returns the appropriate "sun#2"-like string' do

      class Rufus::Scheduler::CronLine
        public :monthdays
      end

      cl = Rufus::Scheduler::CronLine.new('* * * * *')

      expect(cl.monthdays(local(1970, 1, 1))).to eq(%w[ thu#1 thu#-5 ])
      expect(cl.monthdays(local(1970, 1, 7))).to eq(%w[ wed#1 wed#-4 ])
      expect(cl.monthdays(local(1970, 1, 14))).to eq(%w[ wed#2 wed#-3 ])

      expect(cl.monthdays(local(2011, 3, 11))).to eq(%w[ fri#2 fri#-3 ])
    end
  end

  describe '#frequency' do

    it 'returns the shortest delta between two occurrences' do

      expect(Rufus::Scheduler::CronLine.new(
        '* * * * *').frequency).to eq(60)
      expect(Rufus::Scheduler::CronLine.new(
        '* * * * * *').frequency).to eq(1)

      expect(Rufus::Scheduler::CronLine.new(
        '5 23 * * *').frequency).to eq(24 * 3600)
      expect(Rufus::Scheduler::CronLine.new(
        '5 * * * *').frequency).to eq(3600)
      expect(Rufus::Scheduler::CronLine.new(
        '10,20,30 * * * *').frequency).to eq(600)

      expect(Rufus::Scheduler::CronLine.new(
        '10,20,30 * * * * *').frequency).to eq(10)
    end

    it 'spots B-A vs C-B asymmetry in five-field forms' do

      expect(Rufus::Scheduler::CronLine.new(
        '10,17,30 * * * *').frequency).to eq(7 * 60)
      expect(Rufus::Scheduler::CronLine.new(
        '10,23,30 * * * *').frequency).to eq(7 * 60)
      expect(Rufus::Scheduler::CronLine.new(
        '23,10,30 * * * *').frequency).to eq(7 * 60)
    end

    it 'spots B-A vs C-B asymmetry in six-field forms' do

      expect(Rufus::Scheduler::CronLine.new(
        '10,17,30 * * * * *').frequency).to eq(7)
      expect(Rufus::Scheduler::CronLine.new(
        '10,23,30 * * * * *').frequency).to eq(7)
      expect(Rufus::Scheduler::CronLine.new(
        '23,10,30 * * * * *').frequency).to eq(7)
    end

    it 'handles crontab steps syntax in five-field forms' do

      expect(Rufus::Scheduler::CronLine.new(
        '*/10 * * * *').frequency).to eq(10 * 60)
      expect(Rufus::Scheduler::CronLine.new(
        '* */10 * * *').frequency).to eq(60) # "*" all minutes [0..59]
      expect(Rufus::Scheduler::CronLine.new(
        '0 */10 * * *').frequency).to eq(4 * 60 * 60) # 2000 to 0000
    end

    it 'handles crontab steps syntax in six-field forms' do

      expect(Rufus::Scheduler::CronLine.new(
        '*/10 * * * * *').frequency).to eq(10)
      expect(Rufus::Scheduler::CronLine.new(
        '* */10 * * * *').frequency).to eq(1) # "*" all seconds [0..59]
      expect(Rufus::Scheduler::CronLine.new(
        '0 */10 * * * *').frequency).to eq(10 * 60)
    end
  end

  describe '#brute_frequency' do

    it 'returns the shortest delta between two occurrences' do

      expect(Rufus::Scheduler::CronLine.new(
        '* * * * *').brute_frequency).to eq(60)
      expect(Rufus::Scheduler::CronLine.new(
        '* * * * * *').brute_frequency).to eq(1)

      expect(Rufus::Scheduler::CronLine.new(
        '5 23 * * *').brute_frequency).to eq(24 * 3600)
      expect(Rufus::Scheduler::CronLine.new(
        '5 * * * *').brute_frequency).to eq(3600)
      expect(Rufus::Scheduler::CronLine.new(
        '10,20,30 * * * *').brute_frequency).to eq(600)

      #Rufus::Scheduler::CronLine.new(
      #    '10,20,30 * * * * *').brute_frequency.should == 10
        #
        # takes > 20s ...
    end

    # some combos only appear every other year...
    #
    it 'does not go into an infinite loop' do

      expect(Rufus::Scheduler::CronLine.new(
        '1 2 3 4 5').brute_frequency).to eq(31622400)
    end

    it 'spots B-A vs C-B asymmetry in five-field forms' do

      expect(Rufus::Scheduler::CronLine.new(
        '10,17,30 * * * *').brute_frequency).to eq(7 * 60)
      expect(Rufus::Scheduler::CronLine.new(
        '10,23,30 * * * *').brute_frequency).to eq(7 * 60)
    end

    it 'spots B-A vs C-B asymmetry in six-field forms' do

      expect(Rufus::Scheduler::CronLine.new(
        '10,17,30 * * * * *').brute_frequency).to eq(7)
      expect(Rufus::Scheduler::CronLine.new(
        '10,23,30 * * * * *').brute_frequency).to eq(7)
    end

    it 'handles crontab modulo syntax in five-field forms' do

      expect(Rufus::Scheduler::CronLine.new(
        '*/10 * * * *').brute_frequency).to eq(10 * 60)
      expect(Rufus::Scheduler::CronLine.new(
        '* */10 * * *').brute_frequency).to eq(60) # "*" all minutes [0..59]
      expect(Rufus::Scheduler::CronLine.new(
        '0 */10 * * *').brute_frequency).to eq(4 * 60 * 60) # 2000 to 0000
    end

    it 'handles crontab modulo syntax in six-field forms' do

      expect(Rufus::Scheduler::CronLine.new(
        '*/10 * * * * *').brute_frequency).to eq(10)
      expect(Rufus::Scheduler::CronLine.new(
        '* */10 * * * *').brute_frequency).to eq(1) # "*" all seconds [0..59]
      expect(Rufus::Scheduler::CronLine.new(
        '0 */10 * * * *').brute_frequency).to eq(10 * 60)
    end
  end

  context 'summer time' do

    # let's assume summer time jumps always occur on sundays

    # cf gh-114
    #
    it 'schedules correctly through a switch into summer time' do

      in_zone 'Europe/Berlin' do

        # find the summer jump

        j = Time.parse('2014-02-28 12:00')
        loop do
          jj = j + 24 * 3600
          break if jj.isdst
          j = jj
        end

        # test

        friday = j - 24 * 3600 # one day before

        # verify the playground...
        #
        expect(friday.isdst).to eq(false)
        expect((friday + 24 * 3600 * 3).isdst).to eq(true)

        cl0 = Rufus::Scheduler::CronLine.new('02 00 * * 1,2,3,4,5')
        cl1 = Rufus::Scheduler::CronLine.new('45 08 * * 1,2,3,4,5')

        n0 = cl0.next_time(friday)
        n1 = cl1.next_time(friday)

        expect(n0.strftime('%H:%M:%S %^a')).to eq('00:02:00 TUE')
        expect(n1.strftime('%H:%M:%S %^a')).to eq('08:45:00 MON')

        expect(n0.isdst).to eq(true)
        expect(n1.isdst).to eq(true)

        expect(
          (n0 - 24 * 3600 * 3).strftime('%H:%M:%S %^a')).to eq('23:02:00 FRI')
        expect(
          (n1 - 24 * 3600 * 3).strftime('%H:%M:%S %^a')).to eq('07:45:00 FRI')
      end
    end

    it 'schedules correctly through a switch out of summer time' do

      in_zone 'Europe/Berlin' do

        # find the winter jump

        j = Time.parse('2014-08-31 12:00')
        loop do
          jj = j + 24 * 3600
          break if jj.isdst == false
          j = jj
        end

        # test

        friday = j - 24 * 3600 # one day before

        # verify the playground...
        #
        expect(friday.isdst).to eq(true)
        expect((friday + 24 * 3600 * 3).isdst).to eq(false)

        cl0 = Rufus::Scheduler::CronLine.new('02 00 * * 1,2,3,4,5')
        cl1 = Rufus::Scheduler::CronLine.new('45 08 * * 1,2,3,4,5')

        n0 = cl0.next_time(friday)
        n1 = cl1.next_time(friday)

        expect(n0.strftime('%H:%M:%S %^a')).to eq('00:02:00 MON')
        expect(n1.strftime('%H:%M:%S %^a')).to eq('08:45:00 MON')

        expect(n0.isdst).to eq(false)
        expect(n1.isdst).to eq(false)

        expect(
          (n0 - 24 * 3600 * 3).strftime('%H:%M:%S %^a')).to eq('01:02:00 FRI')
        expect(
          (n1 - 24 * 3600 * 3).strftime('%H:%M:%S %^a')).to eq('09:45:00 FRI')
      end
    end

    it 'correctly increments through a DST transition' do

      expect(
        nt('* * * * * America/Los_Angeles', Time.utc(2015, 3, 8, 9, 59))
      ).to eq(Time.utc(2015, 3, 8, 10, 00))
    end

    it 'correctly increments every minute through a DST transition' do

      in_zone 'America/Los_Angeles' do

        line = cl('* * * * * America/Los_Angeles')

        t = Time.local(2015, 3, 8, 1, 57)

        points =
          [ 0, 1, 2, 3 ].collect do
            t = line.next_time(t)
            t.strftime('%H:%M:%Sl') + ' ' + t.dup.utc.strftime('%H:%M:%Su')
          end

        expect(points).to eq(
          [
            '01:58:00l 09:58:00u',
            '01:59:00l 09:59:00u',
            '03:00:00l 10:00:00u',
            '03:01:00l 10:01:00u'
          ]
        )
      end
    end

    it 'correctly decrements through a DST transition' do

      expect(
        pt('* * * * * America/Los_Angeles', Time.utc(2015, 3, 8, 10, 00))
      ).to eq(Time.utc(2015, 3, 8, 9, 59))
    end

    it 'correctly decrements every minute through a DST transition' do

      in_zone 'America/Los_Angeles' do

        line = cl('* * * * * America/Los_Angeles')

        t = Time.local(2015, 3, 8, 3, 2)

        points =
          [ 0, 1, 2, 3 ].collect do
            t = line.previous_time(t)
            t.strftime('%H:%M:%Sl') + ' ' + t.dup.utc.strftime('%H:%M:%Su')
          end

        expect(points).to eq(
          [
            '03:01:00l 10:01:00u',
            '03:00:00l 10:00:00u',
            '01:59:00l 09:59:00u',
            '01:58:00l 09:58:00u'
          ]
        )
      end
    end
  end
end

