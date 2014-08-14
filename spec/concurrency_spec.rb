require 'spec_helper'

describe Rufus::Scheduler do

  context "when running multiple schedulers side-by-side" do

    class AlwaysLock
      def lock; true; end
      def unlock; true; end
      def locked?; true; end
    end

    class NeverLock
      def lock; false; end
      def unlock; true; end
      def locked?; true; end
    end

    it "only starts if it can acquire a scheduler lock" do
      main = Rufus::Scheduler.new :scheduler_lock => AlwaysLock.new
      backup = Rufus::Scheduler.new :scheduler_lock => NeverLock.new

      expect(main).to be_up
      expect(backup).to be_down
    end

    it "only runs jobs when it can acquire a job lock" do
      main = Rufus::Scheduler.new :job_lock => AlwaysLock.new
      backup = Rufus::Scheduler.new :job_lock => NeverLock.new

      expect(main).to be_up
      expect(backup).to be_up

      counter = 0
      job = proc { counter += 1 }
      main.schedule_in(0, job)
      backup.schedule_in(0, job)

      sleep 0.5

      expect(main.jobs).to be_empty
      expect(backup.jobs.count).to eq(1)
      expect(backup.jobs.first.next_time).to be(false)
      expect(counter).to eq(1)
    end

  end

end
