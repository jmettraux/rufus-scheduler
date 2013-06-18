
#
# Specifying rufus-scheduler
#
# Wed Apr 17 06:00:59 JST 2013
#

Thread.abort_on_exception = true

require 'rufus-scheduler'

def local(*args)
  Time.local(*args)
end
alias lo local

def utc(*args)
  Time.utc(*args)
end


#RSpec.configure do |config|
#end

