require 'lib/rufus-scheduler'
require 'rake'

Gem::Specification.new do |s|
  s.name        = "rufus-scheduler"
  s.version       = Rufus::Scheduler::VERSION
  s.authors       = [ "Ryan Sonnek", "John Mettraux" ]
  s.email       = "ryan@codecrate.com"
  s.homepage      = "http://openwferu.rubyforge.org/scheduler.html"
  s.platform      = Gem::Platform::RUBY
  s.summary       = "scheduler for Ruby (at, cron and every jobs), formerly known as 'openwferu-scheduler'"

  s.require_path    = "lib"
  s.test_file     = "test/test.rb"
  s.has_rdoc      = true
  s.extra_rdoc_files  = [ 'README.txt', 'CHANGELOG.txt', 'CREDITS.txt' ]

  files = FileList[ "{bin,docs,lib,test}/**/*" ]
  files.exclude "rdoc"
  files.exclude "extras"
  s.files = files.to_a
end
