require "fileutils"

module Rufus
  module Lock

    # Returns true if the scheduler has acquired the [exclusive] lock and
    # thus may run.
    #
    # Most of the time, a scheduler is run alone and this method should
    # return true. It is useful in cases where among a group of applications
    # only one of them should run the scheduler. For schedulers that should
    # not run, the method should return false.
    #
    # Out of the box, rufus-scheduler proposes the
    # :lockfile => 'path/to/lock/file' scheduler start option. It makes
    # it easy for schedulers on the same machine to determine which should
    # run (to first to write the lockfile and lock it). It uses "man 2 flock"
    # so it probably won't work reliably on distributed file systems.
    #
    # If one needs to use a special/different locking mechanism, providing
    # overriding implementation for this #lock and the #unlock complement is
    # easy.
    class Flock
      attr_reader :path

      def initialize(path)

        @path = path.to_s
      end

      def lock
        return true if locked?

        @lockfile = nil

        FileUtils.mkdir_p(::File.dirname(@path))

        file = File.new(@path, File::RDWR | File::CREAT)
        locked = file.flock(File::LOCK_NB | File::LOCK_EX)

        return false unless locked

        now = Time.now

        file.print("pid: #{$$}, ")
        file.print("scheduler.object_id: #{self.object_id}, ")
        file.print("time: #{now}, ")
        file.print("timestamp: #{now.to_f}")
        file.flush

        @lockfile = file

        true
      end

      def unlock
        !!(@lockfile.flock(File::LOCK_UN) if @lockfile)
      end

      def locked?
        !!(@lockfile.flock(File::LOCK_NB | File::LOCK_EX) if @lockfile)
      end

    end
  end
end

