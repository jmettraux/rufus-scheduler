
#
# Specifying rufus-scheduler
#
# Wed Apr 17 06:00:59 JST 2013
#

require 'spec_helper'


describe Rufus::Scheduler::EveryJob do

  before :each do
    @scheduler = Rufus::Scheduler.new
  end
  after :each do
    @scheduler.shutdown
  end

  it 'triggers as expected' do

    counter = 0

    @scheduler.every '1s' do
      counter = counter + 1
    end

    sleep 3.5

    expect([ 2, 3 ]).to include(counter)
  end

#  it 'strives to follow the given frequency (gh-181)' do
#
#    duration = 60 * 60
#    a = [ [ 0, Time.now ] ]
#
#    @scheduler.every '60s' do |x|
#      n = Time.now
#      d = n - a.last[1]
#      a << [ d, n ]
#      print "#{d}"
#      print d >= 61 ? "...!!! " : " "
#    end
#
#    sleep duration
#  end

  it 'lets its @next_time change in-flight' do

    times = []

    @scheduler.every '1s' do |job|
      times << Time.now
      job.next_time = EtOrbi::EoTime.now + 3 if times.count == 2
    end

    sleep 0.3 while times.count < 3

    #p [ times[1] - times[0], times[2] - times[1] ]

    expect(times[1] - times[0]).to be > 0.9
    expect(times[1] - times[0]).to be < 1.4
    expect(times[2] - times[1]).to be > 3.0
    expect(times[2] - times[1]).to be < 3.4
  end

  context 'summer time' do

    it 'triggers correctly through a DST transition' do

      job = Rufus::Scheduler::EveryJob.new(@scheduler, '1m', {}, lambda {})
      t1 = ltz('America/Los_Angeles', 2015, 3, 8, 1, 55)
      t2 = ltz('America/Los_Angeles', 2015, 3, 8, 3, 05)
      job.next_time = t1
      occurrences = job.occurrences(t1, t2)

      expect(occurrences.length).to eq(11)
    end
  end

  context 'first_at/in' do

    it 'triggers for the first time at first_at' do

      t = Time.now

      job = @scheduler.schedule_every '3s', :first_at => t + 1 do; end

      sleep 2

      #p [ t, t.to_f ]
      #p [ job.last_time.to_s, job.last_time.to_f, job.last_time - t ]
      #p [ job.first_at.to_s, job.first_at.to_f, job.first_at - t ]
      #puts '.'
      #p [ job.next_time.to_s, job.next_time - t ]

      expect(job.first_at).to be_within_1s_of(t + 1.5)
      expect(job.last_time).to be_within_1s_of(job.first_at)
      expect(job.next_time).to be_within_1s_of(t + 4.5)
    end

    it 'triggers for the first time at first_in' do

      t = Time.now

      job = @scheduler.schedule_every '3s', :first_in => '1s' do; end

      sleep 2

      #p [ t, t.to_f ]
      #p [ job.last_time.to_s, job.last_time.to_f, job.last_time - t ]
      #p [ job.first_at.to_s, job.first_at.to_f, job.first_at - t ]
      #puts '.'
      #p [ job.next_time.to_s, job.next_time - t ]

      expect(job.first_at).to be_within_1s_of(t + 1.5)
      expect(job.last_time).to be_within_1s_of(job.first_at)
      expect(job.next_time).to be_within_1s_of(t + 4.5)
    end

    it 'triggers once at first then repeatedly after the assigned time' do

      t = Time.now
      pt = nil

      job =
        @scheduler.schedule_every '4s', :first_in => '2s' do |j|
          n = Time.now
          if j.count == 1
            expect(n).to be_within_1s_of(t + 2.3, '(count 1)')
          else
            expect(n).to be_within_1s_of(pt + 4.3, "(count #{job.count})")
          end
          pt = n
        end

      expect(job.first_at).to be_within_1s_of(t + 1.5)

      wait_until { job.count == 3 }

      expect(Time.now).to be_within_1s_of(t + 2 + 2 * 4)
    end

    describe '#first_at=' do

      it 'alters @next_time' do

        job = @scheduler.schedule_every '3s', :first_in => '10s' do; end

        fa0 = job.first_at
        nt0 = job.next_time

        job.first_at = Time.now + 3

        fa1 = job.first_at
        nt1 = job.next_time

        expect(nt0).to eq(fa0)
        expect(nt1).to eq(fa1)
      end
    end

    describe '#previous_time' do

      it 'returns the previous #time' do

        t0 = nil
        t1 = nil

        job =
          @scheduler.schedule_every '1s' do |j|
            t1 = EtOrbi::EoTime.now
            t0 = j.previous_time
          end
        t = job.next_time

        sleep 1.4

        expect(t0).to eq(t)
        expect(t1).to be > t
      end
    end
  end
end

