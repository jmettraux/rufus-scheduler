
#
# Testing the 'rufus-scheduler'
#
# John Mettraux at openwfe.org
#
# Thu Feb 14 08:19:10 JST 2008
#

require 'test/unit'
require 'rufus/scheduler'


class Scheduler6Test < Test::Unit::TestCase

    #def setup
    #end

    #def teardown
    #end

    #
    # just a small test
    #
    def test_0

        s = Rufus::Scheduler.new
        s.start

        st = ""
        s0 = -1
        s1 = -2

        t = Time.now + 2

        s.schedule_at t do
            st << "0"
            s0 = Time.now.to_i % 60
        end
        s.schedule_at t do
            st << "1"
            s1 = Time.now.to_i % 60
        end

        sleep 2.5

        assert_equal "01", st
        assert_equal s0, s1
    end
end

