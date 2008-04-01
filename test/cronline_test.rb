
#
# Testing rufus-scheduler
#
# John Mettraux at openwfe.org
#
# Sun Oct 29 16:18:25 JST 2006
#

require 'pp'
require 'test/unit'

require 'rufus/scheduler'


#
# testing the Scheduler's CronLine system
#
class CronLineTest < Test::Unit::TestCase

    #def setup
    #end

    #def teardown
    #end

    def test_0

        dotest "* * * * *", [ [0], nil, nil, nil, nil, nil ]
        dotest "10-12 * * * *", [ [0], [10, 11, 12], nil, nil, nil, nil ]
        dotest "* * * * sun,mon", [ [0], nil, nil, nil, nil, [7, 1] ]
        dotest "* * * * mon-wed", [ [0], nil, nil, nil, nil, [1, 2, 3] ]

        #dotest "* * * * sun,mon-tue", [ [0], nil, nil, nil, nil, [7, 1, 2] ]
        #dotest "* * * * 7-1", [ [0], nil, nil, nil, nil, [7, 1, 2] ]
    end

    def test_1

        dotest "* * * * * *", [ nil, nil, nil, nil, nil, nil ]
        dotest "1 * * * * *", [ [1], nil, nil, nil, nil, nil ]
        dotest "7 10-12 * * * *", [ [7], [10, 11, 12], nil, nil, nil, nil ]
        dotest "1-5 * * * * *", [ [1,2,3,4,5], nil, nil, nil, nil, nil ]
    end

    protected

        def dotest (line, array)

            cl = Rufus::CronLine.new(line)

            assert_equal array, cl.to_array
        end

end
