
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

class Scheduler1Test < Test::Unit::TestCase

    #def setup
    #end

    #def teardown
    #end

    def test_0

        scheduler = OpenWFE::Scheduler.new
        scheduler.sstart

        job_id = scheduler.schedule_every "500", :tags => "Avery" do
            # don't do a thing
        end

        sleep 0.300

        count = nil

        200_000.times do |i|
            break if scheduler.get_job(job_id) == nil
            count = i + 1
        end

        scheduler.sstop

        assert_equal 200_000, count
    end

    def test_1

        scheduler = OpenWFE::Scheduler.new
        scheduler.sstart

        job_id = scheduler.schedule_every "500", :tags => "Avery" do
            # don't do a thing
        end

        sleep 0.300

        count = 1

        200_000.times do
            #assert_equal 1, scheduler.find_jobs("Avery").size
            count = scheduler.find_jobs("Avery").size
            break if count != 1
        end

        scheduler.sstop

        assert_equal 1, count
    end

    #
    # testing "deviation", if I may call it like that...
    #
    def _test_2

        scheduler = OpenWFE::Scheduler.new
        scheduler.sstart
        last = nil
        job_id = scheduler.schedule_every "1s" do
            t = Time.now
            puts t.to_f
        end
        sleep 4 * 60
        scheduler.sstop
    end

end
