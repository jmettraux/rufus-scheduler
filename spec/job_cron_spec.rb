
#
# Specifying rufus-scheduler
#
# Wed Apr 17 06:00:59 JST 2013
#

require 'spec_helper'


describe Rufus::Scheduler::CronJob do

  before :each do
    @scheduler = Rufus::Scheduler.new
  end
  after :each do
    @scheduler.shutdown
  end

  context 'normal' do

    it 'triggers near the zero second' do

      job = @scheduler.schedule_cron '* * * * *' do; end

      sleep_until_next_minute

      expect(job.last_time.to_i % 10).to eq(0)
    end

    context 'when passed a cronline object' do
      it 'triggers near the zero second' do
        cl = Rufus::Scheduler::CronLine.new('* * * * *')
        job = @scheduler.schedule_cron cl do; end

        sleep_until_next_minute

        expect(job.last_time.to_i % 10).to eq(0)
      end
    end
  end

  #context 'sub-minute' do
  #
  #  it 'triggers near the zero second' do
  #
  #    job = @scheduler.schedule_cron '* * * * * *' do; end
  #
  #    sleep 1.5
  #
  #    p job.last_time
  #    p job.last_time.to_f
  #  end
  #end

  context 'first_at/in' do

    it 'does not trigger before first_at is reached' do

      t = Time.now

      job =
        @scheduler.schedule_cron '* * * * * *', :first_in => '3s' do
          triggered = Time.now
        end

      sleep 1

      #p [ t, t.to_f ]
      #p [ job.last_time, job.last_time.to_f ]
      #p [ job.first_at, job.first_at.to_f ]

      expect(job.first_at).to be_within_1s_of(t + 3)
      expect(job.last_time).to eq(nil)
    end

    it 'triggers for the first time at first_at' do

      first_time = nil
      t = Time.now

      job = @scheduler.schedule_cron '* * * * * *', :first_in => '3s' do
        first_time ||= Time.now
      end
      sleep 4.5

      expect(job.first_at).to be_within_1s_of(t + 3)
      expect(first_time).to be_within_1s_of(job.first_at)
    end
  end

  context 'scheduling the cron itself' do

    # for https://github.com/jmettraux/rufus-scheduler/issues/95
    #
    # schedule_cron takes more than 30 seconds, blocking...
    #
    it 'does not sit scheduling and blocking...' do

      n = Time.now
      first = nil

      job = @scheduler.schedule_cron '*/2 * * * * *' do
        first ||= Time.now
      end

      expect(Time.now - n).to be < 1.0

      loop do
        next unless first
        expect(first - n).to be < 4.0
        break
      end
    end
  end

  describe '#next_time' do

    it 'returns the next trigger time' do

      tomorrow = Time.now + 24 * 3600 # tomorrow

      nt =
        @scheduler.schedule_cron("0 0 #{tomorrow.day} * *", lambda {}).next_time

      expect(nt.to_f).to eq(Time.parse(tomorrow.strftime('%Y-%m-%d')).to_f)
      expect(nt.zone._name).to eq(EtOrbi::EoTime.local_tzone._name)
    end

    it 'returns the next trigger time (first_at => Time)' do

      ft = Time.parse('2100-12-31')

      job = @scheduler.schedule_cron('* * 1 * *', :first_at => ft) {}

      nt = job.next_time

      expect(nt.to_f).to eq(ft.to_f)
      expect(nt.zone._name).to eq(EtOrbi::EoTime.local_tzone._name)
    end
  end
end

