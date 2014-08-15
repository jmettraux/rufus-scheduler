require "fileutils"

module Rufus
  module Lock
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

