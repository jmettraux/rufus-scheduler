module Rufus::ExceptionHandlers
  class Default
   def handle_exception(job, exception)
     puts '=' * 80
     puts "scheduler caught exception :"
     puts exception
     exception.backtrace.each { |l| puts l }
     puts '=' * 80
   end
  end
end

