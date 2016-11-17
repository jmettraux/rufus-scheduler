
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
  def cla(cronline_string)
    Rufus::Scheduler::CronLine.new(cronline_string).to_a
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
  def ps(cronline, now)
    Rufus::Scheduler::CronLine.new(cronline).prev_second(now)
  end

  def match(line, time)
    expect(cl(line).matches?(time)).to eq(true)
  end
  def no_match(line, time)
    expect(cl(line).matches?(time)).to eq(false)
  end
  def to_a(line, array)
    expect(cla(line)).to eq(array)
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

    # issue https://github.com/jmettraux/rufus-scheduler/issues/202
    it 'rejects zero increments' do

      expect {
        Rufus::Scheduler::CronLine.new('*/0 * * * *')
      }.to raise_error(
        ArgumentError, '"*/0" increment must be greater than zero'
      )

      expect {
        Rufus::Scheduler::CronLine.new('* */0 * * *')
      }.to raise_error(
        ArgumentError, '"*/0" increment must be greater than zero'
      )
    end

    it 'does not support ranges for L' do

      expect { cl '* * 15-L * *' }.to raise_error(
        ArgumentError, 'cannot parse "15-L"')
      expect { cl '* * L/4 * *' }.to raise_error(
        ArgumentError, 'cannot parse "L/4"')
    end

    it 'does not support multiple Ls' do

      expect { cl '* * L,L * *' }.to raise_error(
        ArgumentError, 'found duplicates in "L,L"')
    end

    it 'raises if L is used for something else than days' do

      expect { cl '* L * * *' }.to raise_error(
        ArgumentError, "invalid cronline: '* L * * *'")
    end

    it 'accepts L for day-of-week' do

      expect(
        cla '* * * * 5L'
      ).to eq(
        [ [ 0 ], nil, nil, nil, nil, nil, [ '5#-1' ], nil ]
      )
      expect(
        cla '* * * * FRIL'
      ).to eq(
        [ [ 0 ], nil, nil, nil, nil, nil, [ '5#-1' ], nil ]
      )
    end

    it 'accepts negative days' do

      to_a('* * 8,-8 * *', [[0], nil, nil, [-8,8], nil, nil, nil, nil ])
    end

    it 'accepts negative day ranges' do

      to_a('* * -10--8 * *', [[0], nil, nil, [-10,-9,-8], nil, nil, nil, nil ])
    end

    it 'rejects day descending ranges' do

      expect { cl('* * 10-8 * *') }.to raise_error(
        ArgumentError, '"10-8" descending day ranges not allowed')
      expect { cl('* * -8--10 * *') }.to raise_error(
        ArgumentError, '"-8--10" descending day ranges not allowed')
    end

    it 'rejects negative/positive day ranges' do

      expect { cl('* * 8--2 * *') }.to raise_error(
        ArgumentError, '"8--2" positive/negative ranges not allowed')
      expect { cl('* * -2-8 * *') }.to raise_error(
        ArgumentError, '"-2-8" positive/negative ranges not allowed')
    end

    it 'rejects out of range input' do

      expect { cl '60-62 * * * *' }.to raise_error(
        ArgumentError, '"60-62" is not in range 0..59')
      expect { cl '62 * * * *' }.to raise_error(
        ArgumentError, '"62" is not in range 0..59')
      expect { cl '60 * * * *' }.to raise_error(
        ArgumentError, '"60" is not in range 0..59')
      expect { cl '* 25-26 * * *' }.to raise_error(
        ArgumentError, '"25-26" is not in range 0..24')
      expect { cl '* 25 * * *' }.to raise_error(
        ArgumentError, '"25" is not in range 0..24')
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

        now = Rufus::Scheduler::ZoTime.new(-3600, nil)

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

        now =
          Rufus::Scheduler::ZoTime.new(local(2008, 12, 31, 23, 59, 59, 0), nil)

        expect(nt('* * * * *', now)).to eq(now + 1)
      end
    end

    it 'computes the next occurence correctly in local TZ (TZ not specified)' do

      now = local(1970, 1, 1)

      expect(nt('* * * * *', now)).to eq(zlocal(1970, 1, 1, 0, 1))
      expect(nt('* * * * sun', now)).to eq(zlocal(1970, 1, 4))
      expect(nt('* * * * * *', now)).to eq(zlocal(1970, 1, 1, 0, 0, 1))
      expect(nt('* * 13 * fri', now)).to eq(zlocal(1970, 2, 13))

      expect(nt('10 12 13 12 *', now)).to eq(zlocal(1970, 12, 13, 12, 10))
        # this one is slow (1 year == 3 seconds)
      expect(nt('* * 1 6 *', now)).to eq(zlocal(1970, 6, 1))

      expect(nt('0 0 * * thu', now)).to eq(zlocal(1970, 1, 8))
    end

    it 'computes the next occurence correctly in UTC (TZ specified)' do

      z = 'Europe/Stockholm'
      now = Rufus::Scheduler::ZoTime.parse("1970-1-1 00:00:00 #{z}")

      expect(nt("* * * * * #{z}", now)).to eq(ztu(z, 1969, 12, 31, 23, 1))
      expect(nt("* * * * sun #{z}", now)).to eq(ztu(z, 1970, 1, 3, 23))
      expect(nt("* * * * * * #{z}", now)).to eq(ztu(z, 1969, 12, 31, 23, 0, 1))
      expect(nt("* * 13 * fri #{z}", now)).to eq(ztu(z, 1970, 2, 12, 23))

      expect(nt("10 12 13 12 * #{z}", now)).to eq(ztu(z, 1970, 12, 13, 11, 10))
      expect(nt("* * 1 6 * #{z}", now)).to eq(ztu(z, 1970, 5, 31, 23))

      expect(nt("0 0 * * thu #{z}", now)).to eq(ztu(z, 1970, 1, 7, 23))
    end

    it 'computes the next time correctly when there is a sun#2 involved' do

      expect(nt('* * * * sun#1', zlocal(1970, 1, 1))).to eq(zlocal(1970, 1, 4))
      expect(nt('* * * * sun#2', zlocal(1970, 1, 1))).to eq(zlocal(1970, 1, 11))

      expect(nt('* * * * sun#2', zlocal(1970, 1, 12))).to eq(zlocal(1970, 2, 8))
    end

    it 'computes next time correctly when there is a sun#2,sun#3 involved' do

      expect(
        nt('* * * * sun#2,sun#3', zlo(1970, 1, 1))).to eq(zlo(1970, 1, 11))
      expect(
        nt('* * * * sun#2,sun#3', zlo(1970, 1, 12))).to eq(zlo(1970, 1, 18))
    end

    it 'understands sun#L and co' do

      expect(nt('* * * * sunL', zlo(1970, 1, 1))).to eq(zlo(1970, 1, 25))
      expect(nt('* * * * sun#L', zlo(1970, 1, 1))).to eq(zlo(1970, 1, 25))
      expect(nt('* * * * sun#-1', zlo(1970, 1, 1))).to eq(zlo(1970, 1, 25))
    end

    it 'understands 0#L and co' do

      expect(nt('* * * * 0L', zlo(1970, 1, 1))).to eq(zlo(1970, 1, 25))
      expect(nt('* * * * 0#L', zlo(1970, 1, 1))).to eq(zlo(1970, 1, 25))
      expect(nt('* * * * 0#-1', zlo(1970, 1, 1))).to eq(zlo(1970, 1, 25))
    end

    it 'understands sun#-2' do

      expect(nt('* * * * sun#-2', zlo(1970, 1, 1))).to eq(zlo(1970, 1, 18))
    end

    it 'computes the next time correctly when "L" (last day of month)' do

      expect(nt('* * L * *', zlo(1970, 1, 1))).to eq(zlo(1970, 1, 31))
      expect(nt('* * L * *', zlo(1970, 2, 1))).to eq(zlo(1970, 2, 28))
      expect(nt('* * L * *', zlo(1972, 2, 1))).to eq(zlo(1972, 2, 29))
      expect(nt('* * L * *', zlo(1970, 4, 1))).to eq(zlo(1970, 4, 30))
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
        ).to eq(
          ltz('America/New_York', 0, 30, 1, 31, 10, 2004, nil, nil, true, nil)
            # EDT summer time UTC-4
        )
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

      expect(nt('* * * * * *', zlocal(1970, 1, 1, 1, 1, 1))).to(
        eq(zlocal(1970, 1, 1, 1, 1, 2))
      )
      expect(nt('* * * * * *', zlocal(1970, 1, 1, 1, 1, 2))).to(
        eq(zlocal(1970, 1, 1, 1, 1, 3))
      )
      expect(nt('*/10 * * * * *', zlocal(1970, 1, 1, 1, 1, 0))).to(
        eq(zlocal(1970, 1, 1, 1, 1, 10))
      )
      expect(nt('*/10 * * * * *', zlocal(1970, 1, 1, 1, 1, 9))).to(
        eq(zlocal(1970, 1, 1, 1, 1, 10))
      )
      expect(nt('*/10 * * * * *', zlocal(1970, 1, 1, 1, 1, 10))).to(
        eq(zlocal(1970, 1, 1, 1, 1, 20))
      )
      expect(nt('*/10 * * * * *', zlocal(1970, 1, 1, 1, 1, 40))).to(
        eq(zlocal(1970, 1, 1, 1, 1, 50))
      )
      expect(nt('*/10 * * * * *', zlocal(1970, 1, 1, 1, 1, 49))).to(
        eq(zlocal(1970, 1, 1, 1, 1, 50))
      )
      expect(nt('*/10 * * * * *', zlocal(1970, 1, 1, 1, 1, 50))).to(
        eq(zlocal(1970, 1, 1, 1, 2, 00))
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

  describe '#prev_second' do

    it 'returns the time to the closest previous second' do

      t = local(1970, 1, 1, 1, 1, 42)

      expect(ps('35,44 * * * * *', t)).to eq(7)
    end

    context 'when time sec is lower then all cron seconds (gh-177)' do

      it 'returns the time to the last second a minute before' do

        t = local(1970, 1, 1, 1, 1, 42)

        expect(ps('43,44 * * * * *', t)).to eq(58)
      end
    end
  end

  describe '#previous_time' do

    it 'returns the previous time the cron should have triggered' do

      expect(pt('* * * * sun', zlo(1970, 1, 1))
        ).to eq(zlo(1969, 12, 28, 23, 59, 00))
      expect(pt('* * 13 * *', zlo(1970, 1, 1))
        ).to eq(zlo(1969, 12, 13, 23, 59, 00))
      expect(pt('0 12 13 * *', zlo(1970, 1, 1))
        ).to eq(zlo(1969, 12, 13, 12, 00))
      expect(pt('0 0 2 1 *', zlo(1970, 1, 1))
        ).to eq(zlo(1969, 1, 2, 0, 00))

      expect(pt('* * * * * sun', zlo(1970, 1, 1))
        ).to eq(zlo(1969, 12, 28, 23, 59, 59))
    end

    it 'jumps to the previous minute if necessary (gh-177)' do

      t = local(1970, 12, 31, 1, 1, 0) # vanilla
      expect(pt('43,44 * * * * *', t)).to eq(zlo(1970, 12, 31, 1, 0, 44))

      t = local(1970, 12, 31, 1, 1, 30) # 30 < 43 <---- here!
      expect(pt('43,44 * * * * *', t)).to eq(zlo(1970, 12, 31, 1, 0, 44))

      t = local(1970, 12, 31, 1, 1, 43) # 43 <= 43 < 44
      expect(pt('43,44 * * * * *', t)).to eq(zlo(1970, 12, 31, 1, 0, 44))

      t = local(1970, 12, 31, 1, 1, 44) # 44 <= 44
      expect(pt('43,44 * * * * *', t)).to eq(zlo(1970, 12, 31, 1, 1, 43))

      t = local(1970, 12, 31, 1, 1, 59) # 44 < 59
      expect(pt('43,44 * * * * *', t)).to eq(zlo(1970, 12, 31, 1, 1, 44))

      t = local(1970, 12, 31, 1, 1, 30) # a bigger jump
      expect(pt('43,44 10 * * * *', t)).to eq(zlo(1970, 12, 31, 0, 10, 44))
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
        ).to eq(
          ltz('America/New_York', 0, 30, 1, 31, 10, 2004, nil, nil, false, nil)
            # EST time UTC-5
        )
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
          zlo(1999, 12, 31, 20, 59, 00))
    end

    it 'computes correctly when * */10' do

      expect(
        pt('* */10 * * *', lo(2000, 1, 1))).to eq(
          zlo(1999, 12, 31, 20, 59, 00))
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

    it 'matches negative days' do

      no_match '* * -2 * *', utc(1970, 1, 28)
      match '* * -2 * *', utc(1970, 1, 29)
      no_match '* * -2 * *', utc(1970, 1, 30)
    end

    it 'matches negative day ranges' do

      match '* * -5--3 * *', utc(1970, 1, 27)
      match '* * -5--3 * *', utc(1970, 1, 28)

      match '* * -10--5/2 * *', utc(1970, 1, 21)
      match '* * -10--5/2 * *', utc(1970, 1, 23)
      match '* * -10--5/2 * *', utc(1970, 1, 25)
      no_match '* * -10--5/2 * *', utc(1970, 1, 22)
      no_match '* * -10--5/2 * *', utc(1970, 1, 24)
      no_match '* * -10--5/2 * *', utc(1970, 1, 26)
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

  describe '#frequency' do

    it 'returns the shortest delta between two occurrences (5 fields)' do

      expect(Rufus::Scheduler::CronLine.new(
        '* * * * *').frequency).to eq(60)

      expect(Rufus::Scheduler::CronLine.new(
        '5 23 * * *').frequency).to eq(24 * 3600)
      expect(Rufus::Scheduler::CronLine.new(
        '5 * * * *').frequency).to eq(3600)
      expect(Rufus::Scheduler::CronLine.new(
        '10,20,30 * * * *').frequency).to eq(600)
    end

    it 'returns the shortest delta between two occurrences (6 fields)' do

      expect(Rufus::Scheduler::CronLine.new(
        '* * * * * *').frequency).to eq(1)

      expect(Rufus::Scheduler::CronLine.new(
        '10,20,30 * * * * *').frequency).to eq(10)
    end

    it 'spots B-A vs C-B asymmetry (5 fields)' do

      expect(Rufus::Scheduler::CronLine.new(
        '10,17,30 * * * *').frequency).to eq(7 * 60)
      expect(Rufus::Scheduler::CronLine.new(
        '10,23,30 * * * *').frequency).to eq(7 * 60)
      expect(Rufus::Scheduler::CronLine.new(
        '23,10,30 * * * *').frequency).to eq(7 * 60)
    end

    it 'spots B-A vs C-B asymmetry (6 fields)' do

      expect(Rufus::Scheduler::CronLine.new(
        '10,17,30 * * * * *').frequency).to eq(7)
      expect(Rufus::Scheduler::CronLine.new(
        '10,23,30 * * * * *').frequency).to eq(7)
      expect(Rufus::Scheduler::CronLine.new(
        '23,10,30 * * * * *').frequency).to eq(7)
    end

    it 'handles crontab steps syntax (5 fields)' do

      expect(Rufus::Scheduler::CronLine.new(
        '*/10 * * * *').frequency).to eq(10 * 60)
      expect(Rufus::Scheduler::CronLine.new(
        '* */10 * * *').frequency).to eq(60) # "*" all minutes [0..59]
      expect(Rufus::Scheduler::CronLine.new(
        '0 */10 * * *').frequency).to eq(4 * 60 * 60) # 2000 to 0000
    end

    it 'handles crontab steps syntax (6 fields)' do

      expect(Rufus::Scheduler::CronLine.new(
        '*/10 * * * * *').frequency).to eq(10)
      expect(Rufus::Scheduler::CronLine.new(
        '* */10 * * * *').frequency).to eq(1) # "*" all seconds [0..59]
      expect(Rufus::Scheduler::CronLine.new(
        '0 */10 * * * *').frequency).to eq(10 * 60)
    end
  end

  describe '#brute_frequency' do

    it 'returns the shortest delta between two occurrences (5 fields)' do

      expect(Rufus::Scheduler::CronLine.new(
        '* * * * *').brute_frequency).to eq(60)

      expect(Rufus::Scheduler::CronLine.new(
        '5 23 * * *').brute_frequency).to eq(24 * 3600)
      expect(Rufus::Scheduler::CronLine.new(
        '5 * * * *').brute_frequency).to eq(3600)
      expect(Rufus::Scheduler::CronLine.new(
        '10,20,30 * * * *').brute_frequency).to eq(600)
    end

    it 'returns the shortest delta between two occurrences (6 fields)' do

      expect(Rufus::Scheduler::CronLine.new(
        '* * * * * *').brute_frequency).to eq(1)

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

    it 'spots B-A vs C-B asymmetry (5 fields)' do

      expect(Rufus::Scheduler::CronLine.new(
        '10,17,30 * * * *').brute_frequency).to eq(7 * 60)
      expect(Rufus::Scheduler::CronLine.new(
        '10,23,30 * * * *').brute_frequency).to eq(7 * 60)
    end

    it 'spots B-A vs C-B asymmetry (6 fields)' do

      expect(Rufus::Scheduler::CronLine.new(
        '10,17,30 * * * * *').brute_frequency).to eq(7)
      expect(Rufus::Scheduler::CronLine.new(
        '10,23,30 * * * * *').brute_frequency).to eq(7)
    end

    it 'handles crontab modulo syntax (5 fields)' do

      expect(Rufus::Scheduler::CronLine.new(
        '*/10 * * * *').brute_frequency).to eq(10 * 60)
      expect(Rufus::Scheduler::CronLine.new(
        '* */10 * * *').brute_frequency).to eq(60) # "*" all minutes [0..59]
      expect(Rufus::Scheduler::CronLine.new(
        '0 */10 * * *').brute_frequency).to eq(4 * 60 * 60) # 2000 to 0000
    end

    it 'handles crontab modulo syntax (6 fields)' do

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
          4.times.collect do
            t = line.next_time(t)
            t.to_utc_comparison_s
          end

        expect(points).to eq([
          '0158-8(0958)',
          '0159-8(0959)',
          '0300-7(1000)',
          '0301-7(1001)'
        ])
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
          4.times.collect do
            t = line.previous_time(t)
            t.to_utc_comparison_s
          end

        expect(points).to eq([
          '0301-7(1001)',
          '0300-7(1000)',
          '0159-8(0959)',
          '0158-8(0958)'
        ])
      end
    end

    it 'correctly increments when entering DST' do

      in_zone 'America/Los_Angeles' do

        line = cl('*/10 * * * * America/Los_Angeles')

        t = Time.local(2015, 3, 8, 1, 40)
        t1 = t.dup

        points = []
        while t1 - t < 1 * 3600
          t1 = line.next_time(t1)
          points << t1.to_utc_comparison_s
        end

        expect(points).to eq(%w[
          0150-8(0950)
          0300-7(1000)
          0310-7(1010)
          0320-7(1020)
          0330-7(1030)
          0340-7(1040)
        ])
      end
    end
  end

  context 'fall time' do

    it 'correctly increments through a DST transition' do

      expect(
        nt('* * * * * America/Los_Angeles', Time.utc(2015, 11, 1, 9, 59))
      ).to eq(Time.utc(2015, 11, 1, 10, 00))
    end

    it 'correctly increments every minute through a DST transition' do

      in_zone 'America/Los_Angeles' do

        line = cl('* * * * * America/Los_Angeles')

        #t = Time.local(2015, 11, 1, 1, 57)
          #
          # --> 2015-11-01 01:57:00 -0800 (already PST)

        t = Time.local(0, 57, 1, 1, 11, 2015, nil, nil, true, nil)
          #
          # --> 2015-11-01 01:57:00 -0700 (still PDT)

        points =
          4.times.collect do
            t = line.next_time(t)
            t.to_utc_comparison_s
          end

        expect(points).to eq([
          '0158-7(0858)',
          '0159-7(0859)',
          '0100-8(0900)',
          '0101-8(0901)'
        ])
      end
    end

    it 'correctly decrements through a DST transition' do

      expect(
        pt('* * * * * America/Los_Angeles', Time.utc(2015, 11, 1, 10, 00))
      ).to eq(Time.utc(2015, 11, 1, 9, 59))
    end

    it 'correctly decrements every minute through a DST transition' do

      in_zone 'America/Los_Angeles' do

        line = cl('* * * * * America/Los_Angeles')

        t = Time.local(0, 2, 1, 1, 11, 2015, nil, nil, true, nil)
          #
          # try to force PST

        # TODO: at some point, try to find out if the latest jRuby still
        #       exhibits that behaviour, report to them if necessary

        points =
          (0..3).collect do
            t = line.previous_time(t)
            t.to_utc_comparison_s
          end

        if t.zone == 'PST'
          expect(points).to eq([
            '0101-8(0901)',
            '0100-8(0900)',
            '0159-7(0859)',
            '0158-7(0858)'
          ])
        else
          expect(points).to eq([
            '0101-7(0801)',
            '0100-7(0800)',
            '0059-7(0759)',
            '0058-7(0758)'
          ])
        end
      end
    end

    it 'correctly increments when leaving DST' do

      in_zone 'America/Los_Angeles' do

        line = cl('*/10 * * * * America/Los_Angeles')

        t = Time.local(2015, 11, 1, 0, 40)
        t1 = t.dup

        points = []
        while t1 - t < 2 * 3600
          t1 = line.next_time(t1)
          points << t1.to_utc_comparison_s
        end

        expect(points).to eq([
          '0050-7(0750)', # | PDT
          '0100-7(0800)', # |
          '0110-7(0810)', # V
          '0120-7(0820)',
          '0130-7(0830)',
          '0140-7(0840)',
          '0150-7(0850)',
          '0100-8(0900)', # + PST
          '0110-8(0910)', # |
          '0120-8(0920)', # V
          '0130-8(0930)',
          '0140-8(0940)'
        ])
      end
    end
  end
end

