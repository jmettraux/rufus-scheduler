require File.join(File.dirname(__FILE__), '/spec_base')

describe Rufus::ExceptionHandlers::Default do
  before(:each) do
    # explicitly specifiy this in the test file - it's the default now, but might not be forever
    @s = start_scheduler(:exception_handler => Rufus::ExceptionHandlers::Airbrake.new)
  end

  after(:each) do
    stop_scheduler(@s)
  end

  it 'notifies airbrake about exceptions' do
    ab = double('Airbrake') 
    ab.should_receive(:notify) do |exception|
      exception.message.should == 'Houston we have a problem'
    end

    @s.in 0.400 do
      raise 'Houston we have a problem'
    end

  end
end
