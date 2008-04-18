
#
# Testing OpenWFE
#
# John Mettraux at openwfe.org
#
# Fri Apr 18 11:29:18 JST 2008
#

require 'test/unit'
require 'openwfe/util/scheduler'


#
# testing otime and the scheduler
#

class SchedulerNameTest < Test::Unit::TestCase

    #def setup
    #end

    #def teardown
    #end

    def test_0

        scheduler = OpenWFE::Scheduler.new
        scheduler.sstart

        sleep 0.350 if defined?(JRUBY_VERSION)

        t = scheduler.instance_variable_get(:@scheduler_thread)

        assert_equal "rufus scheduler", t[:name]

        scheduler.stop
    end

    def test_1

        scheduler = OpenWFE::Scheduler.new :thread_name => "genjiguruma"
        scheduler.sstart

        sleep 0.350 if defined?(JRUBY_VERSION)

        t = scheduler.instance_variable_get(:@scheduler_thread)

        assert_equal "genjiguruma", t[:name]

        scheduler.stop
    end

end
