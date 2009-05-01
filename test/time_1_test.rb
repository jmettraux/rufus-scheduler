
#
# Testing the rufus-scheduler
#
# John Mettraux at openwfe.org
#
# Fri Feb 29 11:18:48 JST 2008
#

require File.dirname(__FILE__) + '/test_base'


#
# testing otime
#
class Time1Test < Test::Unit::TestCase

  def test_0

    tts 0, '0s'
    tts 0, '0m', { :drop_seconds => true }
    tts 60, '1m'
    tts 61, '1m1s'
    tts 3661, '1h1m1s'
    tts 24 * 3600, '1d'
    tts 7 * 24 * 3600 + 1, '1w1s'
    tts 30 * 24 * 3600 + 1, '4w2d1s'
  end

  def test_1

    tts 30 * 24 * 3600 + 1, '1M1s', { :months => true }
  end

  def test_2

    tts 0.120 + 30 * 24 * 3600 + 1, "4w2d1s120"
    tts 0.130, '130'
    tts 61.127, '1m', { :drop_seconds => true }
  end

  def test_3

    tdh 0, {}
    tdh 0.128, { :ms => 128 }
    tdh 60.127, { :m => 1, :ms => 127 }
    tdh 61.127, { :m => 1, :s => 1, :ms => 127 }
    tdh 61.127, { :m => 1 }, { :drop_seconds => true }
  end

  protected

  def tts (seconds, time_string, options={})

    assert_equal(
      time_string,
      Rufus::to_time_string(seconds, options),
      "#{seconds} seconds did not map to '#{time_string}'")
  end

  def tdh (seconds, time_hash, options={})

    assert_equal(
      time_hash,
      Rufus::to_duration_hash(seconds, options))
  end

end
