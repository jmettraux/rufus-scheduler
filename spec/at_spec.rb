
require 'spec_helper'


describe Rufus::Scheduler do

  before :each do
    @scheduler = Rufus::Scheduler.new
  end
  after :each do
    @scheduler.shutdown
  end

  describe '#at' do

    it 'adds a job'
    it 'returns a job'
    it 'removes the job after execution'
  end
end

