
#
# Testing the 'rufus-scheduler'
#
# John Mettraux at openwfe.org
#
# Sat Jan 26 20:05:57 JST 2008
#

require 'test/unit'
require 'rufus/scheduler'


class Scheduler5Test < Test::Unit::TestCase

    #def setup
    #end

    #def teardown
    #end

    #
    # Testing the :first_at parameter
    #
    def test_0

        s = Rufus::Scheduler.new
        s.start

        $count = 0

        fa = Time.now + 3
        
        s.schedule_every "1s", :first_at => fa do
            $count += 1
        end

        sleep 1

        assert_equal 0, $count

        sleep 3

        assert_equal 1, $count

        sleep 1

        assert_equal 2, $count

        s.stop
    end

    #
    # Testing the :first_in parameter
    #
    def test_1

        s = Rufus::Scheduler.new
        s.start

        $count = 0

        s.schedule_every "1s", :first_in => "3s" do
            $count += 1
        end

        sleep 1

        assert_equal 0, $count

        sleep 3

        assert_equal 1, $count

        sleep 1

        assert_equal 2, $count

        s.stop
    end
end

