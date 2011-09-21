require 'airbrake'

module Rufus::ExceptionHandlers
  class Airbrake
    def handle_exception(job, exception)
      puts "Notifying airbrake of exception:"
      puts exception
      exception.backtrace.each { |l| puts l }
      ::Airbrake.notify(exception)
    end
  end
end
