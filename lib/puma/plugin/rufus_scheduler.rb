require "puma/plugin"

Puma::Plugin.create do
  def start(launcher)
    in_background do
      relative_path = ENV["RUFUS_SCHEDULER_PATH"] || "config/scheduler.rb"
      absolute_path = File.expand_path(relative_path, Dir.pwd)

      if File.exist?(absolute_path)
        eval(File.read(absolute_path))
      else
        launcher.log_writer.error "Rufus Scheduler file not found at #{absolute_path}"
      end
    end
  end
end
