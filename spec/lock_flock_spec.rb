
#
# Specifying rufus-scheduler
#
# Tue Aug 13 05:58:48 JST 2013
#

require 'spec_helper'


describe Rufus::Lock::Flock do

  before :each do
    @lock_path = '.rufus-scheduler.lock'
    @lock = Rufus::Lock::Flock.new(@lock_path)
  end

  after :each do

    FileUtils.rm_f(@lock_path)
    FileUtils.rm_f('lock.txt')
  end

  context ':lock => Rufus::Lock::File.new(path)' do

    it 'writes down a .rufus-scheduler.lock file' do
      @lock.lock

      line = File.read(@lock_path)

      expect(line).to match(/pid: #{$$}/)
    end

    it '"flocks" the lock file' do
      @lock.lock

      f = File.new(@lock_path, 'a')

      expect(f.flock(File::LOCK_NB | File::LOCK_EX)).to eq(false)
    end
  end
end

