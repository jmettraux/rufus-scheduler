
#
# Specifying rufus-scheduler
#
# Tue Aug 13 05:58:48 JST 2013
#

require 'spec_helper'


describe Rufus::Scheduler do

  after :each do

    FileUtils.rm_f('.rufus-scheduler.lock')
    FileUtils.rm_f('lock.txt')
  end

  context ':lockfile => true' do

    it 'writes down a .rufus-scheduler.lock file' do

      s = Rufus::Scheduler.new :lockfile => true

      line = File.read('.rufus-scheduler.lock')

      #p line
      line.should match(/pid: #{$$}/)
    end

    it '"flocks" the lock file' do

      s = Rufus::Scheduler.new :lockfile => true

      f = File.new('.rufus-scheduler.lock', 'r')

      f.flock(File::LOCK_NB | File::LOCK_EX).should == false
    end

    it 'prevents newer schedulers from starting' do

      s0 = Rufus::Scheduler.new :lockfile => true
      s1 = Rufus::Scheduler.new :lockfile => true

      s0.started_at.should_not == nil
      s1.started_at.should == nil
    end

    it 'releases the lockfile when shutting down' do

      s = Rufus::Scheduler.new :lockfile => true

      s.shutdown(:kill)

      f = File.new('.rufus-scheduler.lock', 'r')

      f.flock(File::LOCK_NB | File::LOCK_EX).should == 0
    end
  end

  context ':lockfile => "filename"' do

    it 'writes down the lockfile' do

      s = Rufus::Scheduler.new :lockfile => './lock.txt'

      line = File.read('lock.txt')

      #p line
      line.should match(/pid: #{$$}/)
    end
  end
end

