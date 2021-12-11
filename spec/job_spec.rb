
#
# Specifying rufus-scheduler
#
# Wed Apr 17 06:00:59 JST 2013
#

require 'spec_helper'


describe Rufus::Scheduler::Job do

  # specify behaviours common to all job classes

  before :each do

    @taoe = Thread.abort_on_exception
    Thread.abort_on_exception = false

    @ose = $stderr
    $stderr = StringIO.new

    @scheduler = Rufus::Scheduler.new
  end

  after :each do

    @scheduler.shutdown

    Thread.abort_on_exception = @taoe

    $stderr = @ose
  end

  describe '#last_time' do

    it 'returns nil if the job never fired' do

      job = @scheduler.schedule_in '10d' do; end

      expect(job.last_time).to eq(nil)
    end

    it 'returns the last time the job fired' do

      job = @scheduler.schedule_in '0s' do; end

      wait_until { job.last_time }
    end
  end

  describe '#threads' do

    it 'returns an empty list when the job is not running' do

      job = @scheduler.schedule_in('1d') {}

      expect(job.threads.size).to eq(0)
    end

    it 'returns an empty list after the job terminated' do

      job = @scheduler.schedule_in('0s') {}

      sleep 0.8

      expect(job.threads.size).to eq(0)
    end

    it 'lists the threads the job currently runs in' do

      job =
        @scheduler.schedule_in('0s') do
          sleep(1)
        end

      wait_until { job.threads.size > 0 }

      expect(job.threads.first[:rufus_scheduler_job]).to eq(job)
    end
  end

  describe '#kill' do

    it 'has no effect if the job is not running' do

      job = @scheduler.schedule_in '10d' do; end

      tls = Thread.list.size

      job.kill

      expect(Thread.list.size).to eq(tls)
    end

    it 'makes the threads vacant' do

      counter = 0

      job =
        @scheduler.schedule_in '0s' do
          sleep 2
          counter = counter + 1
        end

      sleep 1

      v0 = @scheduler.work_threads(:vacant).size
      a0 = @scheduler.work_threads(:active).size

      job.kill

      sleep 2

      v1 = @scheduler.work_threads(:vacant).size
      a1 = @scheduler.work_threads(:active).size

      expect(counter).to eq(0)

      expect(v0).to eq(0)
      expect(a0).to eq(1)

      expect(v1).to eq(1)
      expect(a1).to eq(0)
    end
  end

  describe '#running?' do

    it 'returns false when the job is not running in any thread' do

      job = @scheduler.schedule_in('1d') {}

      expect(job.running?).to eq(false)
    end

    it 'returns true when the job is running in at least one thread' do

      job = @scheduler.schedule_in('0s') { sleep(1) }

      wait_until { job.running? }
    end
  end

  describe '#scheduled?' do

    it 'returns true when the job is scheduled' do

      job = @scheduler.schedule_in('1d') {}

      expect(job.scheduled?).to eq(true)
    end

    it 'returns false when the job is not scheduled' do

      job = @scheduler.schedule_in('0.1s') {}

      sleep 0.4

      expect(job.scheduled?).to eq(false)
    end

    it 'returns true for repeat jobs that are running' do

      job = @scheduler.schedule_interval('0.4s') { sleep(10) }

      wait_until { job.running? }

      expect(job.running?).to eq(true)
      expect(job.scheduled?).to eq(true)
    end

    it 'returns false if job is unscheduled' do

      job = @scheduler.schedule_interval('0.1s') { sleep 0.1 }
      job.unschedule

      sleep 0.3

      expect(job.running?).to eq(false)
      expect(job.scheduled?).to eq(false)
    end
  end

  describe '#call' do

    it 'calls the job (like it were a proc)' do

      counter = 0

      job =
        @scheduler.schedule_in('0.5s') do
          counter = counter + 1
        end
      job.call

      wait_until { counter > 1 }

      expect(counter).to eq(2)
    end
  end

  describe '#call(true)' do

    it 'calls the job and let the scheduler handle errors' do

      $err = nil

      def @scheduler.on_error(job, err)
        $err = "#{job.class} #{job.original} #{err.message}"
      rescue
        p $!
      end

      job =
        @scheduler.schedule_in('1d') do
          fail 'again'
        end

      job.call(true)

      expect($err).to eq('Rufus::Scheduler::InJob 1d again')
    end
  end

  describe '#call(false)' do

    it 'calls the job and let errors slip through' do

      job =
        @scheduler.schedule_in('1d') do
          fail 'fast'
        end

      begin

        #job.call(false)
        job.call # false is the default

        expect(false).to eq(true)

      rescue => ex

        expect(ex.message).to eq('fast')
      end
    end
  end

  context 'job-local variables' do

    describe '#[]=' do

      it 'sets a job-local variable' do

        job =
          @scheduler.schedule_every '1s' do |job|
            job[:counter] ||= 0
            job[:counter] += 1
          end

        wait_until { job[:counter] && job[:counter] > 1 }
      end
    end

    describe '#[]' do

      it 'returns nil if there is no such entry' do

        job = @scheduler.schedule_in '1s' do; end

        expect(job[:nada]).to eq(nil)
      end

      it 'returns the value of a job-local variable' do

        job = @scheduler.schedule_in '1s' do; end
        job[:x] = :y

        expect(job[:x]).to eq(:y)
      end
    end

    describe '#key?' do

      it 'returns true if there is an entry with the given key' do

        job = @scheduler.schedule_in '1s' do; end
        job[:x] = :y

        expect(job.key?(:a)).to eq(false)
        expect(job.key?(:x)).to eq(true)
      end
    end

    describe '#has_key?' do

      it 'returns true if there is an entry with the given key' do

        job = @scheduler.schedule_in '1s' do; end
        job[:x] = :y

        expect(job.has_key?(:a)).to eq(false)
        expect(job.has_key?(:x)).to eq(true)
      end
    end

    describe '#keys' do

      it 'returns the array of keys of the job-local variables' do

        job = @scheduler.schedule_in '1s' do; end
        job[:x] = :y
        job['hello'] = :z
        job[123] = {}

        expect(job.keys.sort_by { |k| k.to_s }).to eq([ 123, 'hello', :x ])
      end
    end

    describe '#values' do

      it 'returns the array of values of the job-local variables' do

        job = @scheduler.schedule_in '1s' do; end
        job[:x] = :y
        job['hello'] = :z
        job[123] = {}

        expect(job.values).to eq([ :y, :z, {} ])
      end
    end

    describe '#entries' do

      it 'returns the array of entry pairs of the job-local variables' do

        job = @scheduler.schedule_in '1s' do; end
        job[:x] = :y
        job['hello'] = :z
        job[123] = {}

        expect(job.entries).to eq([ [ :x, :y ], [ 'hello', :z ], [ 123, {} ] ])
      end
    end

    it 'can be set at job scheduling time' do

      j0 = @scheduler.schedule_in '1s', locals: { a: :alpha } do; end
      j1 = @scheduler.schedule_in '1s', l: { a: :aleph } do; end

      expect(j0[:a]).to eq(:alpha)
      expect(j1[:a]).to eq(:aleph)
    end

    it 'is accessible to pre, post, and around hooks before first run' do

      value = rand

      job =
        @scheduler.schedule_in('0.01s', l: { one: value }, times: 1) do
          $out << "in the job #{value}"
        end

      $out = []

      def @scheduler.on_pre_trigger(job)
        $out << "pre #{job[:one]}"
      end
      def @scheduler.on_post_trigger(job)
        $out << "post #{job[:one]}"
      end
      def @scheduler.around_trigger(job)
        $out << "around-pre #{job[:one]}"
        yield
        $out << "around-post #{job[:one]}"
      end

      wait_until { $out.size > 4 }

      expect($out).to eq([
        "pre #{value}",
        "around-pre #{value}",
        "in the job #{value}",
        "around-post #{value}",
        "post #{value}"
      ])
    end

    describe '#name' do

      it 'returns the job name' do

        j = @scheduler.schedule_in '10d', name: 'alice' do; end

        expect(j.name).to eq('alice')
      end
    end

    describe '#location' do

      it 'returns the job location in code' do

        j = @scheduler.schedule_in '10d', name: 'alice' do; end

        l = j.location

        expect(l[0]).to match(/\/rufus-scheduler\/spec\/job_spec\.rb$/)
        expect(l[1]).to eq(__LINE__ - 5)
      end

      class InstanceHandler
        def call(job, time); end
      end

      it 'returns the right location for a callable instance job' do

        j = @scheduler.schedule_in '10d', InstanceHandler

        l = j.source_location

        expect(l[0]).to match(/\/rufus-scheduler\/spec\/job_spec\.rb$/)
        expect(l[1]).to eq(__LINE__ - 10)
      end

      it 'returns the right location for a callable class job' do

        j =
          @scheduler.schedule_in('10h', Class.new do
            def call; end
          end)

        l = j.source_location

        expect(l[0]).to match(/\/rufus-scheduler\/spec\/job_spec\.rb$/)
        expect(l[1]).to eq(__LINE__ - 6)
      end
    end

    describe '#locals' do

      it 'returns the locals hash, as is' do

        j = @scheduler.schedule_in '1s', locals: { a: :aa, b: :bb } do; end

        expect(j.locals).to eq(a: :aa, b: :bb)
      end
    end
  end

  context ':tag / :tags => [ t0, t1 ]' do

    it 'accepts one tag' do

      job = @scheduler.schedule_in '10d', tag: 't0' do; end

      expect(job.tags).to eq(%w[ t0 ])
    end

    it 'accepts an array of tags' do

      job = @scheduler.schedule_in '10d', tag: %w[ t0 t1 ] do; end

      expect(job.tags).to eq(%w[ t0 t1 ])
    end

    it 'turns tags into strings' do

      job = @scheduler.schedule_in '10d', tags: [ 1, 2 ] do; end

      expect(job.tags).to eq(%w[ 1 2 ])
    end
  end

  context 'blocking: true' do

    it 'runs the job in the same thread as the scheduler thread' do

      job = @scheduler.schedule_in('0s', blocking: true) { sleep(1) }

      sleep 0.4

      expect(job.threads.first).to eq(@scheduler.thread)

      sleep 1.4

      expect(job.threads.size).to eq(0)
    end
  end

  context 'default one thread per job behaviour' do

    it 'runs the job in a dedicated thread' do

      job = @scheduler.schedule_in('0s') { sleep(1) }

      sleep 0.4

      expect(job.threads.first).not_to eq(@scheduler.thread)

      sleep 1.4

      expect(job.threads.size).to eq(0)
    end
  end

  context ':allow_overlapping / :allow_overlap / :overlap' do

    context 'default (overlap: true)' do

      it 'lets a job overlap itself' do

        job = @scheduler.schedule_every('0.3') { sleep(5) }

        sleep 3

        expect(job.threads.size).to be > 1
      end
    end

    context 'when overlap: false' do

      it 'prevents a job from overlapping itself' do

        job = @scheduler.schedule_every('0.3', overlap: false) { sleep(5) }

        wait_until { job.threads.size > 0 }

        expect(job.threads.size).to eq(1)
      end
    end
  end

  context ':mutex' do

    context 'mutex: "mutex_name"' do

      it 'prevents concurrent executions' do

        j0 =
          @scheduler.schedule_in('0s', mutex: 'vladivostok') do
            sleep(3)
          end
        j1 =
          @scheduler.schedule_in('0s', mutex: 'vladivostok') do
            sleep(3)
          end

        wait_until { j0.threads.size + j1.threads.size > 0 }

        if j0.threads.any?
          expect(j0.threads.size).to eq(1)
          expect(j1.threads.size).to eq(0)
        else
          expect(j0.threads.size).to eq(0)
          expect(j1.threads.size).to eq(1)
        end

        expect(@scheduler.mutexes.keys).to eq(%w[ vladivostok ])
      end
    end

    context 'mutex: mutex_instance' do

      it 'prevents concurrent executions' do

        m = Mutex.new

        j0 = @scheduler.schedule_in('0s', mutex: m) { sleep(3) }
        j1 = @scheduler.schedule_in('0s', mutex: m) { sleep(3) }

        wait_until { j0.threads.size + j1.threads.size > 0 }

        if j0.threads.any?
          expect(j0.threads.size).to eq(1)
          expect(j1.threads.size).to eq(0)
        else
          expect(j0.threads.size).to eq(0)
          expect(j1.threads.size).to eq(1)
        end

        expect(@scheduler.mutexes.keys).to eq([])
      end
    end

    context 'mutex: [ array_of_mutex_names_or_instances ]' do

      it 'prevents concurrent executions' do

        j0 = @scheduler.schedule_in('0s', mutex: %w[ a b ]) { sleep(3) }
        j1 = @scheduler.schedule_in('0s', mutex: %w[ a b ]) { sleep(3) }

        wait_until { j0.threads.size + j1.threads.size > 0 }

        if j0.threads.any?
          expect(j0.threads.size).to eq(1)
          expect(j1.threads.size).to eq(0)
        else
          expect(j0.threads.size).to eq(0)
          expect(j1.threads.size).to eq(1)
        end

        expect(@scheduler.mutexes.keys.sort).to eq(%w[ a b ])
      end
    end
  end

  context 'timeout: duration_or_point_in_time' do

    it 'interrupts the job it is stashed to (duration)' do

      counter = 0
      toe = nil

      job =
        @scheduler.schedule_in '0s', timeout: '1s' do
          begin
            counter = counter + 1
            sleep 1.5
            counter = counter + 1
          rescue Rufus::Scheduler::TimeoutError => e
            toe = e
          end
        end

      sleep(3)

      expect(counter).to eq(1)
      expect(toe.class).to eq(Rufus::Scheduler::TimeoutError)
    end

    it 'interrupts the job it is stashed to (point in time)' do

      counter = 0

      job =
        @scheduler.schedule_in '0s', timeout: Time.now + 1 do
          begin
            counter = counter + 1
            sleep 1.5
            counter = counter + 1
          rescue Rufus::Scheduler::TimeoutError => e
          end
        end

      sleep(3)

      expect(counter).to eq(1)
    end

    it 'starts timing when the job enters successfully all its mutexes' do

      t0, t1, t2 = nil

      @scheduler.schedule_in '0s', mutex: 'a' do
        sleep 1
        t0 = Time.now
      end

      job =
        @scheduler.schedule_in '0.5s', mutex: 'a', timeout: '1s' do
          begin
            t1 = Time.now
            sleep 2
          rescue Rufus::Scheduler::TimeoutError => e
            t2 = Time.now
          end
        end

      sleep 3

      expect(t0).to be <= t1

      d = t2 - t1
      expect(d).to be >= 1.0
      expect(d).to be < 1.5
    end

    it 'emits the timeout information to $stderr (default #on_error)' do

      @scheduler.every('1s', timeout: '0.5s') do
        sleep 0.9
      end

      #wait_until { $stderr.string.match?(/Rufus::Scheduler::TimeoutError/) }
        # no worky on older Rubies... so
      wait_until { $stderr.string.match(/Rufus::Scheduler::TimeoutError/) }
    end

    it 'does not prevent a repeat job from recurring' do

      counter = 0

      @scheduler.every('1s', timeout: '0.5s') do
        counter = counter + 1
        sleep 0.9
      end

      wait_until { counter > 1 }
    end
  end

  context 'discard_past: true/false' do

    # specified in spec/job_repeat_spec.rb
  end

  context 'name: / n:' do

    it 'sets the job name' do

      j0 = @scheduler.schedule_in '10d', name: 'Alfred' do; end
      j1 = @scheduler.schedule_in '11d', n: 'Alberich' do; end

      expect(j0.name).to eq('Alfred')
      expect(j1.name).to eq('Alberich')
    end
  end

  context 'work time' do

    describe '#last_work_time' do

      it 'starts at 0' do

        job = @scheduler.schedule_every '5m' do; end

        expect(job.last_work_time).to eq(0.0)
      end

      it 'keeps track of how long the work was upon last trigger' do

        job =
          @scheduler.schedule_in '0.5s' do
            sleep 0.7
          end

        sleep 2

        expect(job.last_work_time).to be >= 0.7
        expect(job.last_work_time).to be < 0.8
      end
    end

    describe '#mean_work_time' do

      it 'starts at 0' do

        job = @scheduler.schedule_every '5m' do; end

        expect(job.mean_work_time).to eq(0.0)
      end

      it 'gathers work times and computes the mean' do

        count = 0

        job =
          @scheduler.schedule_every '0.5s' do |j|
            count = count + 1
            sleep 0.01 * (j.count + 1)
          end

        loop { break if count > 7 }

        expect(job.last_work_time).to be > 0.0
        expect(job.mean_work_time).to be > 0.0
      end
    end
  end

  context 'one time job' do

    describe '#determine_id' do

      it 'returns unique ids' do

        ids = {}

        10_000.times do
          id = @scheduler.in('1y') {}
          break if ids[id]
          ids[id] = true
        end

        expect(ids.length).to eq(10_000)
      end
    end
  end

  context 'repeat job' do

    describe '#determine_id' do

      it 'returns unique ids' do

        ids = {}

        10_000.times do
          id = @scheduler.every('1y') {}
          break if ids[id]
          ids[id] = true
        end

        expect(ids.length).to eq(10_000)
      end
    end
  end
end

