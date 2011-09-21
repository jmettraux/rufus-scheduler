require 'airbrake'

module Rufus::ExceptionHandlers
  class Airbrake
    def handle_exception(job, exception)
      ::Airbrake.notify(exception)
    end
  end
end
