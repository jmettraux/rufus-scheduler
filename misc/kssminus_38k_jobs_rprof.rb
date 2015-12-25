
require 'ruby-prof'
require 'rufus-scheduler'

p [ RUBY_VERSION, RUBY_PLATFORM ]

s = Rufus::Scheduler.new

t = Time.now
profile = RubyProf.profile do
  10.times do
    s.cron('*/5 * * * *') {}
  end
end
p Time.now - t

#printer = RubyProf::GraphPrinter.new(profile)
#printer = RubyProf::GraphHtmlPrinter.new(profile)
#printer = RubyProf::CallTreePrinter.new(profile)
#printer = RubyProf::DotPrinter.new(profile)
#printer.print(STDOUT, {})

printer = RubyProf::CallStackPrinter.new(profile)
File.open('out.html', 'wb') { |f| printer.print(f, {}) }

