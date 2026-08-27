
#
# Specifying rufus-scheduler
#
# Sat Aug 16 05:43:06 JST 2014
# added by @ecin
#

require 'spec_helper'


describe Rufus::Scheduler::FileLock do

  before :each do

    @lock_path = '.rufus-scheduler.lock'
    @lock = Rufus::Scheduler::FileLock.new(@lock_path)
  end

  after :each do

    FileUtils.rm_f(@lock_path)
    FileUtils.rm_f('lock.txt')
  end

  context ':scheduler_lock => Rufus::Scheduler::FileLock.new(path)' do

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

    it 'closes the file when the lock cannot be acquired' do

      file = double(:file, :flock => false)

      allow(File).to receive(:new).and_return(file)
      expect(file).to receive(:close)

      expect(@lock.lock).to eq(false)
    end

    it 'closes and forgets the file when unlocking' do

      @lock.lock
      file = @lock.instance_variable_get(:@lockfile)

      expect(@lock.unlock).to eq(true)
      expect(file.closed?).to eq(true)
      expect(@lock.locked?).to eq(false)
    end
  end
end
