require File.join(File.dirname(__FILE__), '/spec_base')

require 'lib/rufus/exception_handlers/airbrake'

describe Rufus::ExceptionHandlers::Airbrake do
  before(:each) do
    @s = start_scheduler(:exception_handler => Rufus::ExceptionHandlers::Airbrake.new)
  end

  after(:each) do
    stop_scheduler(@s)
  end

  it 'notifies airbrake about exceptions' do
    error = RuntimeError.new('Houston we have a problem')
    ::Airbrake.should_receive(:notify).with(error)

    @s.in 0.400 do
      raise error
    end

    sleep 0.500
    sleep 0.500

  end
end
