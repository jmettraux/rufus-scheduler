
#
# Testing OpenWFE
#
# John Mettraux at openwfe.org
#
# Sun Oct 29 16:18:25 JST 2006
#

require 'test/unit'
require 'openwfe/util/scheduler'


#
# testing otime and the scheduler
#

class SchedulerTest < Test::Unit::TestCase

    #def setup
    #end

    #def teardown
    #end

    def test_scheduler_0

        #Thread.abort_on_exception = true

        $var = nil

        scheduler = OpenWFE::Scheduler.new
        scheduler.sstart

        sid = scheduler.schedule_in('2s', :schedulable => TestSchedulable.new)

        assert \
            sid,
            "scheduler_0 did not return a job id"

        assert \
            (not $var),
            "scheduler_0 is blocking but should not"

        sleep 2.5

        assert_equal 0, scheduler.cron_job_count
        assert_equal 0, scheduler.every_job_count
        assert_equal 0, scheduler.at_job_count
        assert_equal 0, scheduler.pending_job_count

        scheduler.sstop

        #puts ">#{$var}<"

        assert_equal "ok", $var
    end

    def test_scheduler_1

        $var = nil

        scheduler = OpenWFE::Scheduler.new
        scheduler.sstart

        sid = scheduler.schedule_in('1s') do
            $var = "ok..1"
        end

        assert \
            sid,
            "scheduler_1 did not return a job id"

        assert \
            (not $var),
            "scheduler_1 is blocking but should not"

        sleep 2
        scheduler.sstop

        #puts ">#{$var}<"

        assert "ok..1", $var
    end

    #
    # test idea by ara.t.howard on the ruby-talk ml
    #
    def test_scheduler_2

        text = ""

        scheduler = OpenWFE::Scheduler.new()
        scheduler.sstart

        scheduler.schedule_in("1s") do
            text << "one"
            sleep(2)
        end
        scheduler.schedule_in("1s") do
            text << "two"
        end

        sleep(2)

        scheduler.sstop

        #puts text

        assert_equal text, "onetwo"
    end

    #
    # Testing schedule_every()
    #
    def test_scheduler_4

        Thread.abort_on_exception = true

        scheduler = OpenWFE::Scheduler.new()
        scheduler.sstart

        #
        # phase 0

        count = 0

        job_id = scheduler.schedule_every("1s") do
            count += 1
        end

        #puts "0 job_id : " + job_id.to_s

        sleep 3.5

        assert_equal 3, count

        job = scheduler.get_job job_id

        assert_equal "1s", job.schedule_info

        assert_job_count scheduler, 0, 0, 1

        #
        # phase 1

        es = EverySchedulable.new

        job_id = scheduler.schedule_every "500", es

        #puts "1 job_id : " + job_id.to_s
        
        #sleep(3.4) # was a bit soonish for JRuby...
        sleep 3.5

        #assert_job_count scheduler, 0, 0, 2
        assert_equal 6, es.count

        scheduler.unschedule job_id

        sleep 1

        assert_equal 6, es.count

        # done

        scheduler.sstop
    end

    #
    # testing to see if the scheduler immediately executes schedule_in(t)
    # requests where t < scheduler.frequency.
    # (100ms < 250ms)
    #
    def test_scheduler_5

        scheduler = OpenWFE::Scheduler.new
        scheduler.sstart

        touched = false

        scheduler.schedule_in "100" do
            touched = true
        end

        assert touched

        scheduler.sstop
    end

    #
    # Testing to see if a second job with the same id discards the first one.
    #
    def test_scheduler_6

        scheduler = OpenWFE::Scheduler.new
        scheduler.start

        #class << scheduler
        #    attr_reader :pending_jobs
        #end

        value = nil

        scheduler.schedule_in "3s", :job_id => "job" do
            value = 0
        end
        scheduler.schedule_in "2s", :job_id => "job" do
            value = 1
        end

        sleep 0.5

        #puts scheduler.pending_jobs.collect { |j| j.job_id }.inspect
        assert_job_count scheduler, 0, 1, 0

        assert_nil value

        sleep 2.0

        #puts scheduler.pending_jobs.collect { |j| j.job_id }.inspect
        assert_job_count scheduler, 0, 0, 0

        assert_equal 1, value

        sleep 4

        assert_equal 1, value

        scheduler.stop
    end

    #
    # Testing custom precision.
    #
    def test_scheduler_7

        scheduler = Rufus::Scheduler.new(:scheduler_precision => 0.100)

        assert_equal 0.100, scheduler.precision
    end

    #
    # Making sure that a job scheduled in the past is executed immediately
    # and not scheduled.
    #
    # This test also makes sure that schedule_at() understands the
    # time.to_s format.
    #
    def test_8

        scheduler = Rufus::Scheduler.new
        scheduler.start

        var = false

        job_id = scheduler.schedule_at Time.now.to_s do
            var = true
        end

        assert_equal var, true
        assert_nil job_id
    end

    #
    # Scheduling in the past, with :discard_past set to true.
    #
    def test_8b

        scheduler = OpenWFE::Scheduler.new
        scheduler.start

        var = nil

        job_id = scheduler.schedule_at(Time.now.to_s, :discard_past => true) do
            var = "something"
        end

        assert_nil var
        assert_nil job_id

        scheduler.stop
    end

    #
    # Testing restarting the scheduler.
    #
    def test_9

        scheduler = OpenWFE::Scheduler.new
        scheduler.start

        value = nil

        scheduler.schedule_in "2s" do
            value = 0
        end

        assert_nil value

        scheduler.stop

        sleep 0.5

        scheduler.start

        assert_nil value

        sleep 2

        assert_equal value, 0

        scheduler.stop
    end

    def test_10

        e = nil
        begin
            OpenWFE::Scheduler.new.precision = 10
        rescue Exception => e
        end

        assert_not_nil e, "exception not caught"
    end

    protected

        class TestSchedulable
            include OpenWFE::Schedulable

            def trigger (params)
                $var = "ok"
            end
        end

        class EverySchedulable
            include OpenWFE::Schedulable

            attr_accessor :job_id, :count

            def initialize
                @job_id = -1
                @count = 0
            end

            def trigger (params)
                #puts "toto"
                @count += 1
            end
        end

        def assert_job_count (scheduler, cron, at, every)

            assert_equal cron, scheduler.cron_job_count
            assert_equal at, scheduler.at_job_count
            assert_equal every, scheduler.every_job_count
            assert_equal at + every, scheduler.pending_job_count
        end

end
