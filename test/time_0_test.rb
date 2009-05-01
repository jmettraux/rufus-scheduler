
#
# Testing the rufus-scheduler
#
# John Mettraux at openwfe.org
#
# Sun Oct 29 16:18:25 JST 2006
#

require File.dirname(__FILE__) + '/test_base'


#
# testing otime
#
class Time0Test < Test::Unit::TestCase

  def _test_to_iso_date
    #
    # well... this test is not timezone friendly...
    # commented out thus...

    t = 1169019813.93468

    s = Rufus.to_iso8601_date(t)
    puts s

    assert_equal(
      '2007-01-17 02:43:33-0500',
      Rufus.to_iso8601_date(t),
      'conversion to iso8601 date failed')

    d = Rufus.to_ruby_time(s)

    #puts d.to_s

    assert_equal(
      '2007-01-17T02:43:33-0500',
      d.to_s,
      'iso8601 date parsing failed')
  end

  def _test_is_digit

    for i in 0...9
      si = "#{i}"
      assert \
        Rufus::is_digit?(si),
        "'#{si}' should be a digit"
    end

    assert \
      (not Rufus::is_digit?(1)),
      'the integer 1 is not a character digit'
    assert \
      (not Rufus::is_digit?("a")),
      "the character 'a' is not a character digit"
  end

  def test_parse_time_string

    pts '500', 0.5
    pts '1000', 1.0
    pts '1h', 3600.0
    pts '1h10s', 3610.0
    pts '1w2d', 777600.0
    pts '1d1w1d', 777600.0
  end

  protected

  def pts (time_string, seconds)

    assert_equal(
      seconds,
      Rufus::parse_time_string(time_string),
      "'#{time_string}' did not map to #{seconds} seconds")
  end

end
