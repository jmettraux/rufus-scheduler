require File.join(File.dirname(__FILE__), '/spec_base')

describe Rufus::ExceptionHandlers::Default do

  before(:each) do
    # explicitly specifiy this in the test file - it's the default now, but might not be forever
    @s = start_scheduler(:exception_handler => Rufus::ExceptionHandlers::Default.new)
  end
  after(:each) do
    stop_scheduler(@s)
  end

  it 'emits exception messages to stdout' do
    require 'stringio' unless defined?(StringIO) # ruby 1.9

    stdout = $stdout
    s = StringIO.new
    $stdout = s

    @s.in 0.400 do
      raise 'Houston we have a problem'
    end

    sleep 0.500
    sleep 0.500
    $stdout = stdout
    s.close

    s.string.should match(/Houston we have a problem/)
  end
end
